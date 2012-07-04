require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Report::MyTasks do
  def get_instance(opts={})
    return Report::MyTasks.new(1) if opts[:static]
    
    u = User.make!
    p = Project.make!
    Task::Base.create!(:resource => u,
                       :creator  => u,
                       :assignee => u,
                       :project  => p)
    Report::MyTasks.new(u.id)
  end
  it_behaves_like "cacheable report"
end
