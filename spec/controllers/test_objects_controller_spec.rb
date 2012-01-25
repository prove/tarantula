require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe TestObjectsController do
  
  describe "#update" do
    it "should update if everything ok" do
      log_in
      to = flexmock('test object')
      pa = flexmock('project assignment')
      pa.should_receive(:update_attributes!).once.with(:test_object => to)
      flexmock(TestObject).should_receive(:find).once.and_return(to)
      flexmock(ProjectAssignment).should_receive(:find).once.and_return(pa)
      
      put 'update', {:project_id => 1, :user_id => @user.id}
    end
    
    it "should not update other user's test object" do
      log_in
      flexmock(TestObject).should_receive(:find).never
      flexmock(ProjectAssignment).should_receive(:find).never
      
      put 'update', {:project_id => 1, :user_id => (@user.id + 1)}
    end
    
    it "should update test object of a project" do
      log_in
      flexmock(@user).should_receive(:test_area).once.and_return(nil)
      flexmock(controller).should_receive(:include_users_test_area).once
      data = {'some' => 'data', 'tag_list' => 'footag'}
      to = flexmock('test object', :id => 6)      
      flexmock(TestArea).should_receive(:find).and_return([])
      flexmock(TestObject).should_receive(:find).once.and_return(to)
      to.should_receive(:update_with_tags).once.with({'some' => 'data'}, 'footag')
      put 'update', {:project_id => 1, :id => 6, :data => data.to_json}
    end
    
  end
  
  it "#show should call to_data" do
    log_in
    to = flexmock('test object')
    to.should_receive(:to_data).once
    flexmock(TestObject).should_receive(:find).once.with(['6']).and_return(to)
    
    get 'show', {:project_id => 1, :id => 6}
  end
  
  it "#create should create a test object" do
    log_in
    data = {'some' => 'data', 'tag_list' => 'footag'}
    flexmock(controller).should_receive(:include_users_test_area).once
    flexmock(TestArea).should_receive(:find).and_return([])
    flexmock(TestObject).should_receive(:create_with_tags).once.
      with({'some' => 'data', 'project_id' => '1'}, 'footag')
    
    post 'create', {:project_id => 1, :data => data.to_json}
  end
  
  it "#destroy should call toggle deleted" do
    log_in
    to = flexmock('test object', :deleted => false)
    to.should_receive(:update_attributes!).once.with({:deleted => true, :archived => false})
    flexmock(TestObject).should_receive(:find).once.with(['to_id']).\
      and_return(to)
      
    delete 'destroy', {:project_id => 1, :id => 'to_id'}
  end
  
end
