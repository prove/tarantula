require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Import::Service do
  it "create_entity uses create_policy for unique external_id" do
    p = Project.make!
    Case.make!(:external_id => 'id1', :project => p)
    flexmock(Case).should_receive(:create!).never
    
    Import::Service.instance.create_entity(Case, {:external_id => 'id1', 
      :project_id => p.id}, nil, Import::ImportLogger.new(StringIO.new))
  end
  
  it "create_entity uses create_policy for unique external_id, 2" do
    p = Project.make!
    Case.make!(:external_id => 'id1', :project => p)
    flexmock(Case).should_receive(:create!).once
    
    Import::Service.instance.create_entity(Case, {:external_id => 'id2', 
      :project_id => p.id}, nil, Import::ImportLogger.new(StringIO.new))
  end
  
  describe "#find_ext_entity" do
    it "should find if entity with external_id exists in scope" do
      is = Import::Service.instance
      bt = Bugzilla.make!
      prod = BugProduct.make!(:bug_tracker => bt, :external_id => "eid")
      is.find_ext_entity(BugProduct, {:external_id => "eid",
                                      :bug_tracker_id => bt.id}).should == prod
    end
    
    it "should not find if entity with external_id does not exist in scope" do
      is = Import::Service.instance
      bt = Bugzilla.make!
      bt2 = Bugzilla.make!
      prod = BugProduct.make!(:bug_tracker => bt, :external_id => "eid")
      is.find_ext_entity(BugProduct, {:external_id => "eid",
                                      :bug_tracker_id => bt2.id}).should == nil
    end
  end
  
  describe "project update policy" do
    it "should create a task for each deleted req." do
      policy = Import::Service::UpdatePolicies[Project]
      project = flexmock('project', :reload => nil,
                         'requirement_ids' => ['1','2'], :id => 1)
      
      req1 = flexmock('req', :deleted? => false, :name => 'req1',
                      :external_id => '2', :created_by => 1)
      
      flexmock(Requirement).should_receive(:find).once.with('2').and_return(req1)
      
      i_logger = flexmock('logger', :create_msg => nil)
      opts = {}
      atts = {:old_req_ids => ['1','2'],
              :imported_req_ids => ['1']}
      
      flexmock(Task::DeletedRequirement).should_receive(:create!).once
      policy.call(project, atts, i_logger, opts)
    end
    
    it "should create a task for each new req." do
      policy = Import::Service::UpdatePolicies[Project]
      project = flexmock('project', :reload => nil,
                         'requirement_ids' => ['1','2','3'], :id => 1)
      
      req = flexmock('req2', :name => 'req2',
                     :external_id => '3', :created_by => 1)
      
      flexmock(Requirement).should_receive(:find).once.with('3').and_return(req)
      
      i_logger = flexmock('logger', :create_msg => nil)
      opts = {}
      atts = {:old_req_ids => ['1','2'],
              :imported_req_ids => ['1', '2', '3']}
      
      flexmock(Task::NewRequirement).should_receive(:create!).once
      policy.call(project, atts, i_logger, opts)
    end
    
  end
  
end
