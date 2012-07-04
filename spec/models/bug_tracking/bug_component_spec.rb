require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe BugComponent do
  def get_instance(atts={})
    BugComponent.make!(atts)
  end
  
  it_behaves_like "externally_identifiable"
end
