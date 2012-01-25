require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../shared/cacheable_report_spec.rb')

describe Report::MTBF do
  def get_instance(opts={})
    return Report::MTBF.new(1, [1,2], 1) if opts[:static]
    
    bt = Bugzilla.make(:severities => [BugSeverity.make, BugSeverity.make])
    p = Project.make(:bug_tracker_id => bt.id)
    Report::MTBF.new(p.id, '')
  end
  it_should_behave_like "cacheable report"
end
