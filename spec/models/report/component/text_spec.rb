require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe Report::Component::Text do
  def get_instance(opts={})
    Report::Component::Text.new(:p, 'some text..')
  end
  it_behaves_like "report component"
end