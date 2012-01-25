require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../shared/task_spec.rb')

describe Task::DeletedRequirement do
  def get_instance
    Task::DeletedRequirement.new(:resource => Requirement.make)
  end
  it_should_behave_like "task"
end
