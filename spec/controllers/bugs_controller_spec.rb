require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe BugsController do

  it "#index should call #bugs_for_project on bug tracker" do
    log_in
    bt = flexmock('bug_tracker', :fetch_bugs => true)
    proj = flexmock('project', :bug_tracker => bt)
    flexmock(Project).should_receive(:find).once.and_return(proj)
    bt.should_receive(:bugs_for_project).once.with(proj, @user)
    
    get 'index', :project_id => 1, :id => 2
  end
  
  it "#create should redirect to bug post url" do
    log_in
    bt = flexmock('bug_tracker', :fetch_bugs => true)
    proj = flexmock('project', :bug_tracker => bt)
    flexmock(Project).should_receive(:find).once.and_return(proj)
    bt.should_receive(:bug_post_url).once.and_return('http://bug_post_url')
    
    post 'create', :project_id => 1
    response.should redirect_to('http://bug_post_url')
  end
  
  it "#show" do
    log_in
    bt = flexmock('bug_tracker', :fetch_bugs => true)
    proj = flexmock('project', :bug_tracker => bt)
    flexmock(Project).should_receive(:find).once.and_return(proj)
    bt.should_receive('bugs.find').once.and_return(
      flexmock('bug', :link => 'http://buglink'))
    
    get 'show', :project_id => 1, :id => 2
    response.should redirect_to('http://buglink')
  end
  
end
