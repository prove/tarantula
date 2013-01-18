# -*- coding: utf-8 -*-
# Test set executions
class ExecutionsController < ApplicationController
  before_filter :only => [:index, :show] do |c|
    c.require_permission(:any)
  end
  before_filter :only => [:create, :destroy, :update] do |c|
    c.require_permission(['TEST_DESIGNER','MANAGER'])
  end

  before_filter :get_tags_offset_and_filter, :only => [:index]

  before_filter :execution_test_area_permissions, :except => [:index, :create]
  before_filter :include_users_test_area, :only => [:create, :update]

  #  GET /projects/:project_id/users/:user_id/executions
  #   Get all available executions from given project.
  #
  #   TODO: Refactor so that
  #   :user_id is not needed, notice that normally /executions returns
  #   listing for the explorer view.
  #
  #  GET /users/:user_id/executions
  #   Get all executions assigned to current user from each project
  #
  #  GET /test_sets/:test_set_id/executions
  #   List executions from the test_set.
  def index

    if (params[:user_id])
      user = User.find(params[:user_id])

      if (params[:project_id])
        #  GET /projects/:project_id/users/:user_id/executions
        project = Project.find(params[:project_id])
        opts = {
          :conditions => {}
        }

        if (params[:not_completed])
          opts[:conditions][:completed] = false
        end
        if ta = @current_user.test_area(project) and ta.forced
          opts[:conditions][:id] = ta.execution_ids
        end
        if (local_limit = (params[:max] || params[:limit]))
          opts[:limit] = local_limit.to_i
        end

        @active = project.executions.active.ordered.all(opts)
      else
        @active = user.executions.active.ordered
      end
    else
      render :json => get_tagged_items(Execution)
      return
    end

    render :json => {:data => @active.map{|a| a.to_data(:brief)}}
  end

  # ===HTTP POST /executions
  def create
    require_test_area(@data, @project)

    tag_list = @data.delete('tag_list')
    cases = @data.delete('cases')

    set = TestSet.find_by_id(@data['test_set_id'])
    @data['test_set_id'] = set.try(:id)
    @data['test_object'] = @project.test_objects.find_by_name(@data['test_object'])
    @data.merge!('project_id' => @project.id)
    @data.merge!('test_set_version' => set.try(:version))
    @data.merge!('created_by' => @current_user.id)

    @execution = Execution.create_with_assignments!(
      @data, cases, @current_user.id, tag_list)

    render :json => @execution.id, :status => :created
  end

  # ===HTTP GET /executions/:id
  def show
    if params[:format] == 'csv'
      csv = Execution.csv_header
      csv += @execution.to_csv(';', "\r\n", :recurse => 2)
      send_data(csv, :filename => "#{@execution.name.gsub(' ','_')}.csv",
                     :disposition => 'attachment')
    else
      render :json => {:data => [@execution.to_data]}
    end
  end

  # ===HTTP PUT /executions/:id
  def update
    if params[:file]
      import = CsvExchange::Import.new(params[:file], @project.id, 
                                       @current_user.id, false,
                                       CsvExchange::Logger.new(
                                       File.join(Rails.root, 'log', 
                                                 'csv_import.log')))
      import.process
      render :layout => false,
        :inline => "<pre class='csv_update_response'>...</pre>",
        :status => 200
      return
    end
    @data['version'] = params['version'] # TODO: ???????
    @data['updated_by'] = @current_user.id

    cases = @data.delete('cases')
    tag_list = @data.delete('tag_list')

    @execution.update_with_assignments!(@data, cases, tag_list)

    render :json => @execution.id, :status => :ok
  end

  # ===HTTP DELETE /executions/:id
  def destroy
    @execution.update_attributes!({:deleted => !@execution.deleted, :archived => false})
    render :json => @execution.id, :status => :ok
  end

  private
  def execution_test_area_permissions
    test_area_permissions(Execution, params[:id])
  end

  def require_test_area(data, project)
    return if project.test_areas.empty?

    if project.test_areas.find(data['test_area_ids']).empty?
      raise "Test area required!"
    end
  end

end
