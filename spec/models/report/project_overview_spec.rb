require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../shared/cacheable_report_spec.rb')

describe Report::ProjectOverview do
  def get_instance(opts={})
    return Report::ProjectOverview.new(1,5,2) if opts[:static]
    
    p = Project.make
    to = TestObject.make(:project => p)
    Report::ProjectOverview.new(p.id, to.id, nil)
  end
  it_should_behave_like "cacheable report"
end
