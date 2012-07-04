require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe Report::Component::Parameters do
  def get_instance(opts={})
    Report::Component::Parameters.new('a report', {:p1 => 'v1', :p2 => 'v2'})
  end
  it_behaves_like "report component"
end