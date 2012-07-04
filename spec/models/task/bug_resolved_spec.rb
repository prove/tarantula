require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Task::BugResolved do
  def get_instance
    Task::BugResolved.new(:resource => Bug.make!)
  end
  it_behaves_like "task"
end
