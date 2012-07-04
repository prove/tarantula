require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Task::DeletedRequirement do
  def get_instance
    Task::DeletedRequirement.new(:resource => Requirement.make)
  end
  it_behaves_like "task"
end
