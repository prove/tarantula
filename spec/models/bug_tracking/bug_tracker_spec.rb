require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')


describe BugTracker do
  
  it "#take_snapshot should create a BugTrackerSnapshot" do
    bt = BugTracker.new
    flexmock(BugTrackerSnapshot).should_receive(:create!).once.with(
      :bug_tracker => bt, :name => "week 50")
    bt.take_snapshot("week 50")
  end
  
end
