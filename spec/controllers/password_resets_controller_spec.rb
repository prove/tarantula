require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe PasswordResetsController do
  it "#show should activate reset" do
    # no loggging in needed
    pr = flexmock('password reset')
    flexmock(PasswordReset).should_receive(:find_by_link).once.and_return(pr)
    pr.should_receive(:activate).once
    
    get 'show', :id => 'foobar'
  end
  
  it "#create should create a new reset" do
    flexmock(PasswordReset).should_receive(:create).once.with(
      :name_or_email => 'namemail')
    post 'create', :name_or_email => 'namemail'
  end

end
