require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe BugTrackersController do
  describe "#index" do
    it "should list all available trackers" do
      log_in
      bt = flexmock('bug tracker')
      bt.should_receive(:to_tree).once.and_return([])
      flexmock(BugTracker).should_receive(:find).with(:all).and_return([bt])
      get 'index'
    end
  end

  describe "#show" do
    it "should show data of a bug tracker" do
      log_in
      bt = flexmock('bug tracker')
      bt.should_receive(:to_data).once.and_return({})
      flexmock(BugTracker).should_receive(:find).with('1').and_return(bt)
      get 'show', {:id => 1}
    end
  end

  describe "#create" do
    it "should call create! for type Bugzilla" do
      log_in
      data = {'att' => 'val', 'type' => 'Bugzilla'}
      flexmock(Bugzilla).should_receive(:create!).once.with({'att' => 'val', 'type' => 'Bugzilla'}).\
        and_return(flexmock('a new bug tracker', :id => 1))

      post 'create', {:data => data.to_json}
    end
    it "should call create! for type Jira" do
      log_in
      data = {'att' => 'val', 'type' => 'Jira'}
      flexmock(Jira).should_receive(:create!).once.with(Hash).\
        and_return(flexmock('a new bug tracker', :id => 1))

      post 'create', {:data => data.to_json}
    end
  end

  describe "#update" do
    it "should call update_attributes!" do
      log_in
      data = {'att' => 'val'}
      bt = flexmock('bug tracker')
      flexmock(BugTracker).should_receive(:find).once.and_return(bt)
      bt.should_receive(:[]).once.with(:type).and_return('Bugzilla')
      bt.should_receive(:update_attributes!).with({:att => 'val'})

      post 'update', {:data => data.to_json, :id => 1}
    end
  end

  describe "#destroy" do
    it "should call destroy" do
      log_in
      bt = flexmock('bug tracker')
      flexmock(BugTracker).should_receive(:find).once.and_return(bt)
      bt.should_receive(:destroy).once

      delete 'destroy', {:id => 1}
    end
  end

end
