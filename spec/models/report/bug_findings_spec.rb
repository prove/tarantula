require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Report::BugFindings do
  def get_instance(opts={})
    return Report::BugFindings.new(1,[2],nil) if opts[:static]
    
    bt = Bugzilla.make!
    p = Project.make!(:bug_tracker_id => bt.id)
    to = TestObject.make!(:project => p)
    Report::BugFindings.new(p.id, [to.id], nil)
  end
  it_behaves_like "cacheable report"
end
