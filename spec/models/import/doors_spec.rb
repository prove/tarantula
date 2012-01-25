
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Import::Doors do
  
  it "should create a ReqBuilder for each row in input, except header" do
    io_ob = StringIO.new('"Object identifier","Object Level","Priority","Description of the feature","Last modified on","Object Heading"'+"\n"+
                         '"val1","val2","val3","val4","val5","val6"')    

    req_b = flexmock('ReqBuilder')
    req_b.should_receive(:req!).once
    logger = Import::ImportLogger.new(StringIO.new)
    flexmock(Import::ImportLogger).should_receive(:new).once.and_return(logger)
    proj = flexmock('project', 'requirement_ids' => [])
    flexmock(Project).should_receive(:find).with('project_id').and_return(proj)
    
    flexmock(Import::Doors::ReqBuilder).should_receive(:new).once.\
    with(
      ['object_identifier', 'object_level', 'priority', 
       'description_of_the_feature','last_modified_on','object_heading'], 
      ['val1', 'val2', 'val3', 'val4', 'val5', 'val6'],
      'project_id', 'importer_id', logger, Hash).and_return(req_b)
    flexmock(User).should_receive(:find).with('importer_id').and_return(
      flexmock('user', :email => 'foo'))
    i = Import::Doors.new('project_id', 'importer_id', io_ob)
  end
  
  describe "ReqBuilder" do
    
    it "#init_attributes should set attributes according to given parameters" do
      req_b = flexmock(Import::Doors::ReqBuilder.new(
        ['h_1', 'h_2', 'h_3', 'object_identifier'], ['val1', 'val2', 'val3', 1],
        'proj_id', 'importer_id', Import::ImportLogger.new(StringIO.new)))
      req_b.should_receive(:h_1=).once.with('val1')
      req_b.should_receive(:h_2=).once.with('val2')
      req_b.should_receive(:h_3=).once.with('val3')
      req_b.init_attributes
    end
    
    it "#init_attributes should add optional fields to optionals" do
      req_b = Import::Doors::ReqBuilder.new(
        %w(optional_field object_identifier), 
        %w(optional_value id), 
        'proj_id', 'importer_id', Import::ImportLogger.new(StringIO.new))
      req_b.init_attributes
      req_b.optionals.should == {'Optional field' => 'optional_value'}
    end
    
    it "#req! should call init_attributes" do
      req_b = Import::Doors::ReqBuilder.new(
        ['h_1', 'h_2', 'h3'], ['val1', 'val2', 'val3'],
        'proj_id', 'importer_id', Import::ImportLogger.new(StringIO.new))
      req_b = flexmock(req_b)
      req_b.should_receive(:build_req)
      req_b.should_receive(:init_attributes).once
      lambda{ req_b.req! }.should raise_error(StandardError, "No object level!")
    end
    
    describe "#build_req" do
      it "should call Requirement.create! if new req" do
        req_b = Import::Doors::ReqBuilder.new(
          ['h_1', 'h_2', 'h_3', 'object_identifier'], ['val1', 'val2', 'val3', 1],
          'proj_id', 'importer_id', Import::ImportLogger.new(StringIO.new))
        req_b = flexmock(req_b)
        flexmock(Requirement).should_receive(:find).at_least.once
        flexmock(Requirement).should_receive(:create!).once.and_return(
          flexmock('req', :id => 1, :name => 'req'))
        req_b.init_attributes
        req_b.build_req
      end
    
      it "should update existing requirement if old req" do
        req_b = Import::Doors::ReqBuilder.new(
          ['object_identifier','last_modified_on'], [66, '2008-01-05'],
          'proj_id', 'importer_id', Import::ImportLogger.new(StringIO.new))
        req = flexmock('req', :id => 1, :deleted => false,
                       :external_modified_on => Date.parse('2008-01-01'))
        req.should_receive(:update_keeping_cases).once.with(Hash)
        flexmock(Requirement).should_receive(:find).once.and_return(req)      
        req_b.init_attributes
        req_b.build_req
      end
    end
    
    it "#build_case should create a case" do
      req_b = Import::Doors::ReqBuilder.new(
        ['h_1', 'object_heading', 'object_level', 'object_identifier'], 
        ['val1', 'head', 2, 1],
        'proj_id', 'importer_id', Import::ImportLogger.new(StringIO.new), 
        {:parent => [{:requirement_id => 'req_id'}]})
      req_b = flexmock(req_b)
      flexmock(Case).should_receive(:create_with_dummy_step).once
      req_b.init_attributes
      req_b.build_case
    end
    
    it "#build_test_set should create a test set" do
      req_b = Import::Doors::ReqBuilder.new(
        ['h_1', 'object_heading', 'object_level', 'object_identifier'], 
        ['val1', 'head', 2, 1],
        'proj_id', 'importer_id', Import::ImportLogger.new(StringIO.new))
      req_b = flexmock(req_b)
      flexmock(TestSet).should_receive(:create!).once.and_return(
        flexmock('test set', :id => 1, :version => 1, :name => 'foo'))
      req_b.init_attributes
      req_b.build_test_set
    end
    
    # should add cases to test sets
    # cases to reqs
    # tags
    
  end
  
end
