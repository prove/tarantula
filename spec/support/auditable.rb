# For versioned models which include the ChangeHistory model

shared_examples_for "auditable" do
  describe "#change_history" do

    it "should return created as first history info" do
      user = User.make!
      i = get_instance(:updater => user)
      hist = i.change_history
      hist.size.should == 1
      hist.first[:comment].should == 'created'
    end

    it "should return 'unknown' for user where change has no user" do
      user = User.make!
      i = get_instance(:updater => nil)
      hist = i.change_history
      hist.first[:user].should == 'unknown'
    end

    it "should return user, time, and comment for a single change" do
      user = User.make!
      i = get_instance(:updated_by => user.id)
      i.change_comment = 'a comment'
      i.updater = user
      i.save!
      hist = i.change_history
      hist.size.should == 2
      change = hist.first
      change.keys.size.should == 3
      change[:comment].should == 'a comment'
      change[:user].should == user.login
      change[:time].should be_kind_of(Time)
    end

    it "should return multiple changes if present" do
      user = User.make!
      bob = User.make!(:login => 'bob fleming')
      i = get_instance(:updated_by => user.id)
      i.change_comment = 'a comment'
      i.updater = user
      i.save!

      i.change_comment = 'tasty birds'
      i.updater = bob
      i.save!

      hist = i.change_history
      hist.size.should == 3

      hist[0][:comment].should == 'tasty birds'
      hist[0][:user].should == 'bob fleming'

      hist[1][:comment].should == 'a comment'
      hist[1][:user].should == user.login
    end

  end
end
