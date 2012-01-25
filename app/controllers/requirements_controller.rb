class RequirementsController < ApplicationController
  before_filter :get_tags_offset_and_filter, :only => [:index]

  before_filter :only => [:destroy, :create, :update] do |c|
    c.require_permission(['TEST_DESIGNER','MANAGER'])
  end
  before_filter :only => [:index, :show] do |c|
    c.require_permission(:any)
  end
  
  before_filter :requirement_test_area_permissions, :except => [:index, :create]
  before_filter :include_users_test_area, :only => [:create, :update]
  
  def index
    if params[:case_id]
      # Requirements for case, to be displayed in case edit screen.
      reqs = Case.find(params[:case_id]).linked_to_requirements.map(&:to_tree)
      render :json => reqs
    else
      render :json => get_tagged_items(Requirement)      
    end
  end
  
  def show
    render :json => {:data => [@requirement.to_data]}
  end
  
  def destroy
    @requirement.deleted = !@requirement.deleted
    @requirement.archived = false
    @requirement.save!    
    
    render :json => @requirement.id, :status => :ok
  end
  
  def create
    p = Project.find(params[:project_id] || @project.id)
    attributes = @data.symbolize_keys.merge({:project_id => p.id,
                                             :created_by => @current_user.id})
    cases = attributes.delete(:cases).map{|c| Case.find(c)}
    tags = attributes.delete(:tag_list)
    
    req = Requirement.create_with_cases!(attributes, cases, tags)
    
    render :json => req.id, :status => :created
  end
  
  def update
    attributes = @data.symbolize_keys
    cases = attributes.delete(:cases).map{|c| Case.find(c)}
    tags = attributes.delete(:tag_list)
    
    @requirement.update_with_cases!(attributes, cases, tags)
    
    render :json => @requirement.id, :status => :ok
  end
  
  private
   
  def requirement_test_area_permissions
    test_area_permissions(Requirement, params[:id])
  end  
  
end
