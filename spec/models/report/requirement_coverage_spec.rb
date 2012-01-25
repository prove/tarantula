require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../shared/cacheable_report_spec.rb')

describe Report::RequirementCoverage do
  def get_instance(opts={})
    return Report::RequirementCoverage.new(1,1) if opts[:static]
    
    p = Project.make
    Report::RequirementCoverage.new(p.id, nil)
  end
  it_should_behave_like "cacheable report"
end
