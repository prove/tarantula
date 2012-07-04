require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Report::TestEfficiency do
  def get_instance(opts={})
    if opts[:static]
      return Report::TestEfficiency.new(1, 4, [1,2])
    end                                    
    
    p = Project.make!
    to = TestObject.make!(:project => p)
    ta = TestArea.make!(:project => p)
    Report::TestEfficiency.new(p.id, ta.id, [to.id])
  end
  
  it_behaves_like "cacheable report"
end
