require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Task::Review do
  def get_instance
    Task::Review.new(:resource => Case.make)
  end
  it_behaves_like "task"
end
