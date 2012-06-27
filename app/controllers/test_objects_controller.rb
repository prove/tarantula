class TestObjectsController < ApplicationController
  before_filter :get_tags_offset_and_filter, :only => [:index]
  
  before_filter :only => [:create, :destroy] do |c|
    c.require_permission(['TEST_DESIGNER','MANAGER'])
  end
  before_filter :except => [:create, :destroy] do |c|
    c.require_permission(:any)  
  end
  
  before_filter :test_object_test_area_permissions, :except => [:index, :create]
  before_filter :include_users_test_area, :only => [:create, :update]
  
  # GET /projects/x/test_objects
  def index
    render :json => get_tagged_items(TestObject)
  end
  
  # GET /projects/x/test_object/:id
  def show
    if params[:user_id]
      user = User.find(params[:user_id])
      pa = user.project_assignments.\
        find_by_project_id(params[:project_id])
      if pa
        obs = nil
        ta = user.test_area(pa.project)
        obs = ta.test_objects.active.ordered if ta
        obs ||= pa.project.test_objects.active.ordered
        data = obs.map do |to|
          d = to.to_data
          d.merge!(:selected => true) if pa.test_object_id == to.id
          d
        end
      else
        data = []
      end
      render :json => {:data => data}
    else
      render :json => {:data => [@test_object.to_data]} 
    end
  end
  
  # PUT /projects/x/users/y/test_object
  # PUT /projects/:project_id/test_objects/:id
  def update
    if params[:user_id]
      check_user_is_current_user
      get_project_assignment
      @pa.update_attributes!(:test_object => TestObject.find(params[:test_object_id]))
      render :json => @pa.test_object_id
    else
      require_permission(['TEST_DESIGNER','MANAGER'])
      tag_list = @data.delete('tag_list')
      @test_object.update_with_tags(@data, tag_list)
      render :json => @test_object.id
    end
  end
  
  # POST /projects/:project_id/test_objects
  def create
    tag_list = @data.delete('tag_list')
    to = TestObject.create_with_tags(
      @data.merge({'project_id' => params[:project_id]}), tag_list)
    render :json => to.id
  end
  
  # DELETE /projects/:project_id/test_object/:id
  def destroy
    @test_object.update_attributes!({:deleted => !@test_object.deleted, :archived => false})
    render :nothing => true, :status => :ok
  end
  
  private
  
  def check_user_is_current_user
    raise "Permission denied!" if @current_user.id != params[:user_id].to_i
  end
  
  def get_project_assignment
    @pa = ProjectAssignment.find(:first, 
      :conditions => {:project_id => params[:project_id],
                      :user_id => params[:user_id]})
    raise "No project assignment!" unless @pa
  end
  
  def test_object_test_area_permissions
    return if params[:user_id] and %w(update show).include?(params[:action])
    test_area_permissions(TestObject, params[:id])
  end
  
end
