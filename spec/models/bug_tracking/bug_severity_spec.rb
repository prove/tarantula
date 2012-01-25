require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../shared/externally_identifiable.rb')

describe BugSeverity do  
  def get_instance(atts={})
    BugSeverity.make(atts)
  end
  
  it_should_behave_like "externally_identifiable"
  
end
