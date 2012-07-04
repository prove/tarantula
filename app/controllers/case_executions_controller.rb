class CaseExecutionsController < ApplicationController
  before_filter :only => :update do |c|
    c.require_permission(['TEST_ENGINEER','TEST_DESIGNER','MANAGER'])
  end
  before_filter :only => [:index, :show] do |c|
    c.require_permission(:any)
  end
  before_filter :only => [:destroy] do |c|
    c.require_permission(['TEST_DESIGNER', 'MANAGER'])
  end

  # GET /executions/:executions_id/case_executions
  def index
    test_area_permissions(Execution, params[:execution_id])

    render :json => @execution.case_executions.find(:all,
                                       :joins => 'LEFT JOIN case_versions ON case_versions.version = case_executions.case_version AND case_versions.case_id = case_executions.case_id',
                                       :include => [:test_case, :executor]).
      as_json(:only => [:id, :case_id, :case_version, :execution_id,
                        :result, :duration, :position, :assigned_to, :executed_at],
              :methods => [:history, :title, :time_estimate, :executed_by])
  end

  # PUT /executions/:execution_id/case_executions/:id
  # PUT /case_executions/:id
  def update
    if params[:execution_id]
      test_area_permissions(Execution, params[:execution_id])
      case_execution = @execution.case_executions.find(params[:id])
    else
      case_execution = CaseExecution.find(params[:id],
                                          :include => :execution)
      test_area_permissions(Execution, case_execution.execution.id)
    end

    se_data = @data.delete('step_executions')
    case_execution.update_with_steps!(@data, se_data, @current_user)

    render :json => {
      :data => [
                :id => case_execution.id,
                :result => case_execution.result.ui,
                :duration => case_execution.duration,
                :execution => case_execution.execution.long_name
               ]
    }
  end

  def show
    @case_execution = CaseExecution.
      find(
           params[:id],
           :include => [:execution, :test_case, {:step_executions => [:step, :bug]}]
           )
    test_area_permissions(Execution, @case_execution.execution.id)

    render :json => {:data => [@case_execution.to_data(:include_steps)]}
  end

  def destroy
    @case_execution = CaseExecution.find(params[:id])
    @case_execution.destroy_if_not_last
    render :nothing => true, :status => :ok
  end

end
