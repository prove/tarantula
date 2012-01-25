class TasksController < ApplicationController
  # /user/:user_id/tasks
  # /cases/:case_id/tasks
  def index
    res = resource
    tasks = res.tasks.active.ordered.find(:all, 
      :conditions => {:assigned_to => @current_user.id})
    monitored = []    
    if res.is_a?(User)
      monitored = Task::Base.active.ordered.find(:all,
      :conditions => ["created_by = :uid and assigned_to != :uid", 
                     {:uid => @current_user.id}])
    end
    
    render :json => (tasks + monitored).map(&:to_data)
  end
  
  # POST /cases/:case_id/tasks
  # POST /projects/:project_id/tasks
  def create
    @data.merge!({'resource' => resource,
                  'created_by' => @current_user.id})
    @data['assigned_to'] ||= @current_user.id
    
    t = Task::Base.create!(@data)
    render :json => t.id, :status => :ok
  end
  
  # PUT /users/:user_id/tasks/:id
  # PUT /project/:project_id/tasks/:id
  def update
    t = resource.tasks.find(params[:id])
    t.update_attributes!(@data)
    render :json => t.id, :status => :ok
  end
  
  private
  
  def resource
    ret = nil
    [User, Case, Project].each do |res|
      key = "#{res.to_s.underscore}_id"
      if params[key]
        ret = res.find(params[key])
        break
      end
    end
    raise "No resource!" unless ret
    check_rights(ret)
    ret
  end
  
  def check_rights(resource)
    if resource.is_a?(User)
      raise "Permission denied!" if @current_user.id != params[:user_id].to_i
    elsif resource.is_a?(Project)
      raise "Permission denied!" if request.put? and \
        resource.tasks.find(params[:id]).assigned_to != @current_user.id
    else # Case
      test_area_permissions(resource.class, resource.id)
    end
  end
  
end
