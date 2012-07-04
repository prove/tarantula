require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe BugSeverity do  
  def get_instance(atts={})
    BugSeverity.make!(atts)
  end
  
  it_behaves_like "externally_identifiable"
  
end
