require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../shared/cacheable_report_spec.rb')

describe Report::CaseExecutionList do
  def get_instance(opts={})
    return Report::CaseExecutionList.new(1, [1,2], [4,6], 5) if opts[:static]
    
    p = Project.make
    to = TestObject.make(:project => p)
    Report::CaseExecutionList.new(p.id, [to.id], nil) # ,conds
  end
  it_should_behave_like "cacheable report"
end
