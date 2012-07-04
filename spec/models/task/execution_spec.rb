require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Task::Execution do
  def get_instance
    Task::Execution.new(Execution.make, User.make)
  end
  it_behaves_like "task"
end
