class TestAreasController < ApplicationController  
  before_filter {|c| c.require_permission(:any)}

  # GET /projects/:project_id/test_areas
  def index
    @project = Project.find(params[:project_id])
    current_ta = @current_user.test_area(@project)
    
    if current_ta and current_ta.forced
      data = [current_ta.to_tree.merge!({:selected => true, :forced => true})]
      render :json => {:data => data}
      return
    end
    
    data = @project.test_areas.map do |ta|
      tadata = ta.to_tree
      if current_ta and (current_ta.id == ta.id)
        tadata.merge!({:selected => true, :forced => false})
      end
      tadata
    end
    render :json => {:data => data}
  end
  
  # GET /projects/:project_id/users/:user_id/test_area
  def show
    test_area = User.find(params[:user_id]).test_area(params[:project_id])
    
    if test_area
      data = {:id => test_area.id, :forced => test_area.forced}
    else
      data = {:id => nil}
    end
    render :json => {:data => [data]}
  end
  
  # PUT /projects/:project_id/users/:user_id/test_area?test_area_id=X
  def update
    user = User.find(params[:user_id])
    
    test_area = user.test_area(params[:project_id])
    raise "Current test area forced!" if test_area and test_area.forced
    
    user.set_test_area(params[:project_id], params[:test_area_id])
    
    render :nothing => true, :status => :ok
  end

end
