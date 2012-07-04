require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Report::DailyProgress do
  def get_instance(opts={})
    return Report::DailyProgress.new(1,1,1) if opts[:static]
    
    p = Project.make!
    to = TestObject.make!(:project => p)
    Report::DailyProgress.new(p.id, to.id)
  end
  it_behaves_like "cacheable report"
end
