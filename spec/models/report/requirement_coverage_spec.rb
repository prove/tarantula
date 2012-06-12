require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Report::RequirementCoverage do
  def get_instance(opts={})
    return Report::RequirementCoverage.new(1,1) if opts[:static]
    
    p = Project.make!
    Report::RequirementCoverage.new(p.id, nil)
  end
  it_behaves_like "cacheable report"
end
