require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Report::ProjectOverview do
  def get_instance(opts={})
    return Report::ProjectOverview.new(1,5,2) if opts[:static]
    
    p = Project.make!
    to = TestObject.make!(:project => p)
    Report::ProjectOverview.new(p.id, to.id, nil)
  end
  it_behaves_like "cacheable report"
end
