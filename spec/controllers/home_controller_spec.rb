require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe HomeController do
  it "should handle #index" do
    log_in
    get 'index'
    response.should be_success
  end
  
  it "should handle #login" do
    get 'login'
    response.should be_success
  end
  
  it "should handle #login [POST]" do
    u = flexmock('user', :id => 1, :deleted? => false)
    u.should_receive(:latest_project).once.and_return(Project.make!)
    flexmock(User).should_receive(:authenticate).once.with('login', 'password').\
      and_return(u)
    
    post 'login', {:login => 'login', :password => 'password'}
    response.should redirect_to('/')
  end
  
  it "should handle #logout" do
    log_in
    post 'logout'
    response.should redirect_to('/home/login')
  end
end
