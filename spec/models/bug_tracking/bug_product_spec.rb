require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe BugProduct do
  def get_instance(atts={})
    BugProduct.make!(atts)
  end
  
  it_behaves_like "externally_identifiable"
end
