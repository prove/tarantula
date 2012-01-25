require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe TasksController do
  
  it "#index should show tasks for a resource" do
    log_in
    p = flexmock('project')
    p.should_receive('tasks.active.ordered.find').once.and_return []
    flexmock(Project).should_receive(:find).and_return(p)
    flexmock(controller).should_receive(:check_rights).once
    get 'index', :project_id => 1
  end
  
  it "#create should create a task" do
    log_in
    data = {'comment' => 'foo'}.to_json
    
    c = flexmock('case')
    flexmock(Case).should_receive(:find).and_return(c)
    
    flexmock(Task::Base).should_receive(:create!).once.\
      and_return(flexmock('task', :id => 1))
    flexmock(controller).should_receive(:check_rights).once
    
    post 'create', :case_id => 1, :data => data
  end
  
  it "#update calls update_attributes!" do
    log_in
    data = {'comment' => 'foo'}.to_json
    
    c = flexmock('case')
    flexmock(Case).should_receive(:find).and_return(c)
    t = flexmock('task', :id => 1)
    c.should_receive('tasks.find').once.and_return(t)
    t.should_receive(:update_attributes!).once
    
    flexmock(controller).should_receive(:check_rights).once
    
    put 'update', :case_id => 1, :id => 1, :data => data
  end
  
end
