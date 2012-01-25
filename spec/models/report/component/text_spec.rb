require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../shared/report_component_spec.rb')

describe Report::Component::Text do
  def get_instance(opts={})
    Report::Component::Text.new(:p, 'some text..')
  end
  it_should_behave_like "report component"
end