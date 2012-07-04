class BugsController < ApplicationController
  before_filter {|c| c.require_permission(:any)}
  before_filter :require_tracker
  
  # GET /projects/:project_id/bugs
  def index
    @bt.fetch_bugs
    bugs = @bt.bugs_for_project(@project, @current_user)
    render :json => {:data => bugs.map(&:to_data)}
  end
  
  # POST /projects/:project_id/bugs
  # redirects to bug post url of the projects tracker
  def create
    redirect_to @bt.bug_post_url(@project, 
      {:product => params[:product], 
       :step_execution_id => params[:step_execution_id]})
  end
  
  # GET /projects/:project_id/bugs/:id
  # redirect to the bug show url of the tracker
  def show
    bug = @bt.bugs.find(params[:id])
    redirect_to bug.link
  end
  
  private
  
  def require_tracker
    @project = Project.find(params[:project_id])
    @bt = @project.bug_tracker
    raise "No bug tracker!" unless @bt
  end
end
