require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Report::CaseExecutionList do
  def get_instance(opts={})
    return Report::CaseExecutionList.new(1, [1,2], [4,6], 5) if opts[:static]
    
    p = Project.make!
    to = TestObject.make!(:project => p)
    Report::CaseExecutionList.new(p.id, [to.id], nil) # ,conds
  end
  it_behaves_like "cacheable report"
end
