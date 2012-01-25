require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../shared/cacheable_report_spec.rb')

describe Report::ResultsByTestObject do
  def get_instance(opts={})
    return Report::ResultsByTestObject.new(1, 1, [1,2], nil) if opts[:static]
    
    p = Project.make
    to = TestObject.make(:project => p)
    Report::ResultsByTestObject.new(p.id, to.id, to.execution_ids, nil)
  end
  it_should_behave_like "cacheable report"
end

