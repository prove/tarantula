require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../shared/report_component_spec.rb')

describe Report::Component::Formatting do
  def get_instance(opts={})
    Report::Component::Formatting.new(opts)
  end
  it_should_behave_like "report component"
end