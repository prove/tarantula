require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../shared/cacheable_report_spec.rb')

describe Report::BugTrend do
  def get_instance(opts={})
    return Report::BugTrend.new(1) if opts[:static]
    
    bt = Bugzilla.make
    p = Project.make(:bug_tracker_id => bt.id)
    Report::BugTrend.new(p.id)
  end
  it_should_behave_like "cacheable report"
end
