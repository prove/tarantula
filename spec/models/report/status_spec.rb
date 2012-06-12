require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Report::Status do
  def get_instance(opts={})
    return Report::Status.new(1, [4,5], 1) if opts[:static]
    
    bt = Bugzilla.make!
    p = Project.make!(:bug_tracker_id => bt.id)
    Report::Status.new(p.id)
  end
  it_behaves_like "cacheable report"
end
