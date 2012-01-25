require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../shared/cacheable_report_spec.rb')

describe Report::Dashboard do
  def get_instance(opts={})
    return Report::Dashboard.new(1,1, nil, 1) if opts[:static]
    
    u = User.make
    p = Project.make
    to = TestObject.make(:project => p)
    p.assignments << ProjectAssignment.new(:user => u, :group => 'MANAGER')
    Report::Dashboard.new(u.id, p.id, nil, to.id)
  end
  it_should_behave_like "cacheable report"
end
