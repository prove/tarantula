# -*- coding: utf-8 -*-

class UsersController < ApplicationController
  before_filter :get_tags_offset_and_filter, :only => [:index]

  before_filter :only => [:create, :destroy] do |f|
    f.require_permission(['ADMIN'])
  end
  before_filter :except => [:create, :destroy] do |f|
    f.require_permission(:any)
  end

  before_filter :get_user

  #  GET /users
  #   Lists all users.
  #
  #  GET /projects/:project_id/users
  #   Lists users included in a project.
  #
  # Group information won't be included in data if project id is not
  # available.
  #
  # Allow user listings only for the Admin users or users included in the same projects.
  def index

    if params[:project_id] and
        (@current_user.admin? or @current_user.project_ids.include?(params[:project_id].to_i))
      p_id = params[:project_id]
      p_id = @project.id if p_id == 'current'
      active = User.all(
                        :select => 'id, login, deleted, realname',
                        :include => :projects,
                        :conditions => ["project_assignments.group IN \
                                        (#{User::Groups.values.map{|s|"'#{s}'"}.join(',')}) AND projects.id = ? \
                                        AND users.deleted = 0 AND users.login LIKE ? ",
                                        p_id, "%#{@filter}%"]
                        )
    elsif (@current_user.admin?)
      active = User.all(
                        :select => 'id, login, deleted, realname',
                        :conditions => ["deleted=0 AND login LIKE ? ",
                                        "%#{@filter}%"])
    else
      # Users in same projects
      active = User.all(
                        :select => 'id, login, deleted, realname',
                        :include => :projects,
                        :conditions => ["users.deleted=0 AND projects.id IN \
                                        (#{@current_user.project_ids.join(',')}) \
                                        AND users.login LIKE ? ", "%#{@filter}%"])
    end

    render :json => active.map{|a| a.to_tree}
  end

  def deleted
    if (params[:project_id])
      p_id = params[:project_id]
      p_id = @project.id if p_id == 'current'
      deleted = User.all(
                         :select => 'id, login, deleted, realname',
                         :include => :projects,
                         :conditions => {
                           'users.deleted' => true,
                           'projects.id' => p_id
                         })
    else
      deleted = User.all(:select => 'id, login, deleted, realname',
                         :conditions => {:deleted => true})
    end

    render :json => deleted.map{|d| d.to_tree}
  end

  # ===GET /users/:id/permissions
  #   Lists users permission groups in different projects
  # ====Parameters
  # ====Response
  # ====Exceptions
  def permissions
    ret = ''
    @user = User.find(params[:id])
    if (@user.admin?)
      ret = {:data => [{:project_name => 'ALL', :group => 'ADMIN'}]}
    else
      @permissions = @user.project_assignments.find(
        :all, :joins => :project, :conditions => {'projects.deleted' => false})
      ret = {:data => @permissions.as_json(:only => [:group], :methods => [:project_name])}
    end
    render :json => ret
  end

  #  POST /users
  def create
    @user = User.new(@data)

    @user.new_random_password if @user.password.blank?

    @user.save!
    render :json => @user.id, :status => :created
  end

  #  GET /users/:id
  #   Returns user data for :id
  def show
    @user = User.find(params[:id])
    raise "Permission denied." unless \
      ((@current_user.projects & @user.projects).size >= 1 or @current_user.admin?)
    render :json => {:data => [@user.to_data]}
  end

  #  PUT /users/:id
  def update
    raise "Permission denied." unless \
      ((@current_user.id == params[:id].to_i) or @current_user.admin?)
    
    @user = User.find(params[:id])
    if @current_user.admin?
      @user.remove_admin_assignments if @user.admin? and @data['admin'] == 0
    else
      @data.delete('admin')
    end

    # Set attributes.
    @user.update_attributes!(@data)
    render :json => @user.id, :status => :ok
  end

  #  DELETE /users/:id
  #   Removes userdata from db.
  def destroy
    @user = User.find(params[:id])
    @user.toggle!(:deleted)
    render :json => @user.id, :status => :ok
  end

  #  PUT /users/current/selected_project
  #   Changes current project for the user if current user is allowed
  #   to access the project.
  #   TODO: Should be changed to use HTTP status codes.
  def selected_project
    if (@current_user.allowed_in_project?(params[:project_id]))
      project = Project.find(params[:project_id])
      @current_user.latest_project_id = project.id
      @current_user.save!
      @project = project
      render :json => '{"status":true}'
    else
      render :json => '{"status":false}'
    end
  end

  # === GET /users/current/available_groups
  #   Lists user groups for permission selection combobox in project editor.
  def available_groups
    render :json => {:data => User::Groups.collect {|k,v|
        {:value => v, :text => k.to_s.humanize}}}
  end

  private
  # Convert user id parameter
  def get_user
    if (params[:id] == 'current')
      params[:id] = @current_user.id
    end
  end


end
