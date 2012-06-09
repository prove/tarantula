require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe Report::Component::Formatting do
  def get_instance(opts={})
    Report::Component::Formatting.new(opts)
  end
  it_behaves_like "report component"
end