require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ProjectAssignment do
  
  it "delegates realname to user" do
    mock_user_assoc = flexmock('user assoc')
    pa = flexmock(ProjectAssignment.new, :user => mock_user_assoc)
    mock_user_assoc.should_receive(:realname).once
    pa.realname
  end
  
  it "delegates login to user" do    
    mock_user_assoc = flexmock('user assoc')
    pa = flexmock(ProjectAssignment.new, :user => mock_user_assoc)
    
    mock_user_assoc.should_receive(:login).once
    pa.login
  end
  
  it "#project_name calls name on project" do
    mock_project_assoc = flexmock('project assoc')
    pa = flexmock(ProjectAssignment.new, :project => mock_project_assoc)
    
    mock_project_assoc.should_receive(:name).once
    pa.project_name
  end
  
end
