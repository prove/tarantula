require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PasswordReset do
  
  describe "#create" do
    it "should find user by email" do
      flexmock(UserNotifier).should_receive(:deliver_password_reset_link).once
      u = User.make(:email => 'foo@bar.com')
      pr = PasswordReset.create!(:name_or_email => 'foo@bar.com')
      pr.reload.user.should == u
    end
    
    it "should find user by login" do
      flexmock(UserNotifier).should_receive(:deliver_password_reset_link).once
      u = User.make(:login => 'tony')
      pr = PasswordReset.create!(:name_or_email => 'tony')
      pr.reload.user.should == u
    end
    
    it "should allow only one reset per day" do
      flexmock(UserNotifier).should_receive(:deliver_password_reset_link).once
      u = User.make(:login => 'tony')
      PasswordReset.create!(:name_or_email => 'tony')
      pr = PasswordReset.new(:name_or_email => 'tony')
      pr.save.should == false
      pr.errors.should_not be_empty
    end
  end
  
  describe "#activate" do
    it "should raise if already activated" do
      flexmock(UserNotifier).should_receive(:deliver_password_reset_link).once
      u = User.make(:login => 'gary')
      pr = PasswordReset.create!(:name_or_email => 'gary')
      pr.update_attribute(:activated, true)
      lambda {pr.activate}.should raise_error
    end
    
    it "should call appropriate methods" do
      flexmock(UserNotifier).should_receive(:deliver_password_reset_link).once
      flexmock(UserNotifier).should_receive(:deliver_new_password).once
      
      u = User.make(:login => 'gary')
      pr = PasswordReset.create!(:name_or_email => 'gary')
      flexmock(User).should_receive(:find).and_return(flexmock(u))
      u.should_receive(:new_random_password).once
      u.should_receive(:save!).once
      pr.reload
      pr.activate
      pr.activated.should == true
    end
    
  end
  
end
