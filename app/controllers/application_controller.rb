# -*- coding: utf-8 -*-
# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

#require 'ruby-prof'

class ApplicationController < ActionController::Base
  # protect_from_forgery
  before_filter :set_current_user_and_project, :except => [:login]
  before_filter :apply_currents
  before_filter :clean_data

  rescue_from StandardError do |exception|
    logger.debug exception.message+"\n"+(exception.backtrace.join("\n"))
    render :json => exception.message, :status => :forbidden
  end

  # Give more information in case of JSON parse error
  #rescue_from ActiveSupport::JSON::ParseError do |exception|
  #  render :json => exception.message +
  #    ": Testia is unable to handle some special characters or character " +
  #    "combinations. Please check content for special characters " +
  #    "and modify or remove them.",
  #  :status => :forbidden
  #end

  # For tag error, display just message (Tag propably fails because of
  # illegal characters validation, and error message would look bad
  # with redundant information repeated).
  rescue_from Tag::Error do |exception|
    render :json => exception.message, :status => :forbidden
  end

  rescue_from ActiveRecord::StaleObjectError do |exception|
    render :json => "Save Conflict. Object has been modified at same time " +
      " (by someone else). Unable to commit changes. ",
    :status => :forbidden
  end

  rescue_from ConfirmationNeeded do |exception|
    render :json => {:message => exception.message, :status => 409},
                    :status => :conflict
  end

  def require_permission(allowed_groups = nil)
    allowed_groups = User::Groups.values if allowed_groups == :any

    pid = params[:project_id] || @project.id

    raise "require_permission failure!" if pid.nil?

    if (@current_user.admin? or @current_user.allowed_in_project?(pid,allowed_groups))
      return
    end

    # Jos ei päästä mihinkään, niin tästä HTTP 403
    if request.xhr? == true
      raise "Forbidden.Current user is not authorized to access this feature."
    else
      flash[:error] = "Current user is not authorized to access this feature."
      render :layout => "application", :template => "errors/403"
      return false
    end
  end

  private
  # == Get tagged items
  # * all_tags is a list of tags e.g. for all the cases in the project
  #   minus the selected ones
  # * properly offsetted and limited result set is fetched to items
  # * TODO: handle more than a LOAD_LIMIT of tags correctly

  def get_tagged_items(t_class, opts={:include_tags => true, :conditions => '', :conv_method => :to_tree})
    test_area = @current_user.test_area(@project.id)

    if opts[:include_tags]
      all_tags = SmartTag.find_all_tags(@project, t_class, @tags, test_area, @smart_tags)
    else
      all_tags = []
    end

    local_limit = (params && params[:limit] ? params[:limit].to_i : nil) || \
      Testia::LOAD_LIMIT

    @i_limit = (local_limit*(@offset+1)) - all_tags.size
    @i_limit = local_limit if @i_limit > local_limit
    @i_offset = (@offset*local_limit) - all_tags.size
    @i_offset = [@i_offset, 0].max

    items = []
    if @i_limit > 0
      items = t_class.find_with_tags(@tags,
                 { :project    => @project,
                   :filter     => @filter,
                   :offset     => @i_offset,
                   :limit      => @i_limit,
                   :test_area  => test_area,
                   :conditions => opts[:conditions],
                   :smart_tags => @smart_tags })

      items_tree = items.map{|i| i.send(opts[:conv_method])}
    end

    tags_tree = []
    tags_tree = all_tags.map{|t| t.send(opts[:conv_method])} if @offset == 0
    return items_tree if @filter
    tags_tree + items_tree
  end

  def get_tags_offset_and_filter
    @smart_tags, tag_ids = SmartTag.digest(params[:nodes])

    if (tag_ids == ['deleted'])
      @tags = 'deleted'
    elsif (tag_ids == ['archived'])
      @tags = 'archived'
    elsif !tag_ids.empty?
      @tags = Tag.find(:all, :conditions => {:id => tag_ids})
    end

    @offset = params[:offset].to_i || 0

    @filter = params[:filter].gsub(/['\\?*'"`\%#&]/, "") if params[:filter]
    @filter = nil if @filter.blank?
  end

  def apply_currents
    params[:user_id] = @current_user.id if params[:user_id] == 'current'
    params[:project_id] = @project.id if params[:project_id] == 'current'
  end

  def test_area_permissions(klass, id_info, multi=false)
    entities = [klass.find(id_info.to_s.split(','))].flatten
    test_area = @current_user.test_area(@project)

    entities.each do |e|
      if test_area and test_area.forced
        raise "Permission denied! (test area). Please refresh your browser." \
          if !test_area.send(klass.to_s.underscore+'_ids').include?(e.id)
      end
    end

    # set instance variable e.g. @case for Case, etc.
    if !multi
      instance_variable_set("@#{klass.to_s.underscore}", entities.first)
    else
      instance_variable_set("@#{klass.to_s.pluralize.underscore}", entities)
    end
    true
  end

  def include_users_test_area
    if @data and ta = @current_user.test_area(@project)
      @data['test_area_ids'] ||= []
      @data['test_area_ids'].map!(&:to_i)
      @data['test_area_ids'] |= [ta.id]
    end
  end

  # clean input in params[:data] and store in @data
  def clean_data
    if params[:data]
      @data = Sanitizer.instance.\
        clean_data(ActiveSupport::JSON.decode(params[:data]))
    end
  end

  def set_current_user_and_project
    @current_user = User.find(request.env['REMOTE_USER'] || session[:user_id])
    @project = @current_user.latest_project
  end

end
