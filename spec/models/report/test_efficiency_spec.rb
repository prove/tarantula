require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../shared/cacheable_report_spec.rb')

describe Report::TestEfficiency do
  def get_instance(opts={})
    if opts[:static]
      return Report::TestEfficiency.new(1, 4, [1,2])
    end                                    
    
    p = Project.make
    to = TestObject.make(:project => p)
    ta = TestArea.make(:project => p)
    Report::TestEfficiency.new(p.id, ta.id, [to.id])
  end
  
  it_should_behave_like "cacheable report"
end
