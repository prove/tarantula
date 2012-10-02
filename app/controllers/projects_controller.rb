# -*- coding: utf-8 -*-
class ProjectsController < ApplicationController
  before_filter :get_tags_offset_and_filter, :only => [:index]
  before_filter :current_id

  before_filter :only => [:create, :destroy] do |c|
    c.require_permission(['ADMIN'])
  end
  before_filter :only => [:update] do |c|
    c.require_permission(['MANAGER', 'ADMIN'])
  end
  before_filter :except => [:create, :destroy, :update] do |c|
    c.require_permission(:any)
  end

  # ===GET /users/:user_id/projects
  #   Lists projects for current user.
  def index
    conds = "deleted=#{@tags == 'deleted' ? 1 : 0}"
    conds += " AND name LIKE '%#{@filter}%'" if @filter

    if (@current_user.admin?)
        projects = Project.find(:all, :conditions => conds)
    else
        projects = @current_user.projects.find(:all, :conditions => conds)
    end

    data = projects.map do |p|
      p_tree = p.to_tree
      p_tree[:selected] = true if p.id == @project.id
      p_tree
    end

    render :json => data
  end

  # DELETE /projects/x/deleted => PURGE
  # GET /projects/deleted      => get deleted projects
  def deleted
    # the purge
    if request.delete? and params[:id]
      require_permission(['ADMIN'])
      @project = Project.find(params[:id])
      @project.purge!
      render :nothing => true, :status => :ok
      return
    end

    if (@current_user.admin?)
      projects = Project.find(:all, :conditions => {:deleted => 1})
    else
      projects = @current_user.projects.deleted
    end

    render :json => projects.map(&:to_tree)
  end

  def create
    test_areas = @data.delete('test_areas')
    bug_products = @data.delete('bug_products')
    assigned_users = @data.delete('assigned_users')

    @project = Project.create_with_assignments!(@data, assigned_users,
                                                test_areas, bug_products)

    render :json => @project.id, :status => :ok
  end

  def show
    @project = Project.find(params[:id])

    render :json => {:data => [@project.to_data]}
  end

  # Return user's permission group from project.
  def group
    if (@current_user.admin?)
      ret = 'ADMIN'
    else
      @assignment = ProjectAssignment.\
        find_by_project_id_and_user_id(params[:id], params[:user_id])

      ret = (@assignment ? @assignment.group : 'NONE')
    end

    render :json => {:data => ret}
  end

  def update
    @project = Project.find(params[:id])

    assigned_users = @data.delete('assigned_users')
    test_areas = @data.delete('test_areas')
    bug_products = @data.delete('bug_products')

    @project.update_with_assignments!(@current_user, @data, assigned_users,
                                      test_areas, bug_products)

    render :json => @project.id, :status => :ok
  end

  # DELETE /projects/:id
  def destroy
    ok = false
    @project = Project.find(params[:id])
    if (@project.toggle!(:deleted))
      ok = true
    end
    #render :json => "{\"status\":#{ok}}"
    render :json => @project.id, :status => :ok
  end

  def priorities
    render :json => {:data => Project::Priorities}
  end

  def products
    project = Project.find(params[:id])
    bt = project.bug_tracker
    raise "Project has no bug tracker!" unless bt

    if ta = @current_user.test_area(project) and ta.forced
      products = ta.bug_products
    else
      products = project.bug_products
    end

    render :json => {:data => products.map(&:to_data)}
  end

  private

  def current_id
    params[:id] = @project.id if params[:id] == 'current'
  end

end
