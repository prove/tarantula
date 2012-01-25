require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../shared/cacheable_report_spec.rb')

describe Report::MyTasks do
  def get_instance(opts={})
    return Report::MyTasks.new(1) if opts[:static]
    
    u = User.make
    p = Project.make
    Task::Base.create!(:resource => u,
                       :creator  => u,
                       :assignee => u,
                       :project  => p)
    Report::MyTasks.new(u.id)
  end
  it_should_behave_like "cacheable report"
end
