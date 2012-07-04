require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Task::NewRequirement do
  def get_instance
    Task::NewRequirement.new(:resource => Requirement.make)
  end
  it_behaves_like "task"
end
