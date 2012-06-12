require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Report::ResultsByTestObject do
  def get_instance(opts={})
    return Report::ResultsByTestObject.new(1, 1, [1,2], nil) if opts[:static]
    
    p = Project.make!
    to = TestObject.make!(:project => p)
    Report::ResultsByTestObject.new(p.id, to.id, to.execution_ids, nil)
  end
  it_behaves_like "cacheable report"
end

