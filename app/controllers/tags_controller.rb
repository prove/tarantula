# -*- coding: utf-8 -*-

class TagsController < ApplicationController
  before_filter :only => [:create, :destroy, :update] do |c|
    c.require_permission(['TEST_DESIGNER','MANAGER'])
  end

  # === POST /projects/:project_id/tags
  # Tags multiple items with provided tag string.
  #
  # * params[:type] taggable items type {executions, cases, test_sets,...}
  # * params[:items] array of tagged item ids
  # * params[:tags] comma separated line of tags
  def create
    project = Project.find(params[:project_id])
    @data.symbolize_keys!
   
    if !%w(executions cases test_sets requirements test_objects).include?(@data[:type])
      raise StandardError.new, "Invalid :type parameter for tags creation (#{@data[:type]})"
    end
    
    # Strip empty tags and spaces from tag string
    tags = @data[:tags].split(',')
    tags.map!{ |t| t.strip != '' ? t : nil}
    tags.compact!    
    @data[:tags] = tags.join(',')
    
    @data[:tags] ||= ""
    @data[:items] ||= []

    @items = project.send(@data[:type]).\
      find(:all, :conditions => { :id => @data[:items] }, :include => :tags)

    @items.each{|i|
      old_tags = i.tags_to_s
      i.tag_with([@data[:tags],old_tags].join(',').chomp(','))
    }

    render :json => 'ok', :status => :created
  end

  # DELETE /projects/:project_id/tags/:id?taggable_type=X
  def destroy
    @project = Project.find(params[:project_id])
    @project.tags.find(params[:id]).destroy
    render :nothing => true, :status => :ok
  end

  # PUT /projects/:project_id/tags/:id
  # needs params[:name]
  def update
    @project = Project.find(params[:project_id])
    t = @project.tags.find(params[:id])
    t.update_attributes!({:name => params[:name]})

    render :json => t.to_tree, :status => :ok
  end

  # GET /projects/:project_id/tags/?taggable_type=X
  def index
    @project = Project.find(params[:project_id])
    
    @tags = @project.tags.all(
                              :conditions =>
                              (params[:taggable_type].nil? ?
                               {} : {:taggable_type => params[:taggable_type]}),
                              :select => "DISTINCT(name)",
                              # DO NOT INCLUDE EMPTY TAGS
                              # Currently TaggingObserver deletes empty tags,
                              # but database may still contain empty tags from earlier
                              # implementation.
                              :joins => "INNER JOIN taggings ON taggings.tag_id = tags.id"
                              )

    render :json => {:data => @tags.map(&:to_tree)}, :status => :ok
  end

end
