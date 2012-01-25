require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../shared/cacheable_report_spec.rb')

describe Report::Status do
  def get_instance(opts={})
    return Report::Status.new(1, [4,5], 1) if opts[:static]
    
    bt = Bugzilla.make
    p = Project.make(:bug_tracker_id => bt.id)
    Report::Status.new(p.id)
  end
  it_should_behave_like "cacheable report"
end
