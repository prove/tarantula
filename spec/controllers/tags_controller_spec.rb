require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe TagsController do
  before(:each) do
    log_in
  end
  
  it "#destroy should call remove_from_project" do
    @project = flexmock('project')
    flexmock(Project).should_receive(:find).and_return(@project)
    @tag = flexmock('tag', :to_tree => {:key => 'val'})
    
    @tag.should_receive(:destroy).once
    @project.should_receive('tags.find').once.and_return(@tag)
    delete 'destroy', {:id => 1, :project_id => 1}
  end
  
  it "#update calls update_attributes! for tag" do
    @project = flexmock('project')
    flexmock(Project).should_receive(:find).and_return(@project)
    @tag = flexmock('tag', :to_tree => {:key => 'val'})
    
    @project.should_receive('tags.find').once.and_return(@tag)
    @tag.should_receive(:update_attributes!).once
    put 'update', {:taggable_type => 'Case', :name => 'new_name', 
                   :project_id => 1, :id => 1}
  end
  
  it "#create should call tag_with properly when old tags" do
    @project = flexmock('project')
    flexmock(Project).should_receive(:find).and_return(@project)
    
    data = ActiveSupport::JSON.encode(:tags => "tag1,tag2",
                                      :items => [1],
                                      :type => 'cases')
    a_case = flexmock('case', :tags_to_s => '')
    @project.should_receive('cases.find').and_return([a_case])
    a_case.should_receive(:tag_with).once.with('tag1,tag2')
    
    post 'create', {:project_id => 1, :data => data}
  end
  
  it "#create should call tag_with properly when no old tags" do
    @project = flexmock('project')
    flexmock(Project).should_receive(:find).and_return(@project)
    
    data = ActiveSupport::JSON.encode(:tags => "tag1,tag2",
                                      :items => [1],
                                      :type => 'cases')
    a_case = flexmock('case', :tags_to_s => 'tag0')
    @project.should_receive('cases.find').and_return([a_case])
    a_case.should_receive(:tag_with).once.with('tag1,tag2,tag0')
    
    post 'create', {:project_id => 1, :data => data}
  end
  
end
