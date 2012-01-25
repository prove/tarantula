require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../shared/externally_identifiable.rb')

describe BugComponent do
  def get_instance(atts={})
    BugComponent.make(atts)
  end
  
  it_should_behave_like "externally_identifiable"
end
