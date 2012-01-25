require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe ReportController do
  
  describe "case execution list" do
    it "should report by test object" do
      log_in
      
      flexmock(@user).should_receive(:test_area).once
      
      flexmock(Report::CaseExecutionList).should_receive(:new).once.\
        with(@project.id, Array, nil, false, nil, nil, nil)
    
      flexmock(controller).should_receive(:respond_to_formats)
    
      get 'case_execution_list', :test_object_ids => '1'
    end
    
    it "should report by execution" do
      log_in
      
      flexmock(@user).should_receive(:test_area).once
      
      flexmock(Report::CaseExecutionList).should_receive(:new).once.\
        with(@project.id, nil, Array, false, nil, nil, nil)
    
      flexmock(controller).should_receive(:respond_to_formats)
    
      get 'case_execution_list', :execution_ids => '1'
    end
    
  end
  
  it "should report test result status" do
    log_in
    flexmock(Project).should_receive(:find).and_return(
      flexmock('project', :id => 'p_id'))
    flexmock(@user).should_receive(:test_area).once
    flexmock(Report::TestResultStatus).should_receive(:new).once
    
    controller.should_receive(:respond_to_formats).once
    
    get 'test_result_status', :test_object_ids => '1'
  end
  
  it "should report results by test object" do
    log_in
    flexmock(Project).should_receive(:find).and_return(
      flexmock('project', :id => 'p_id'))
    flexmock(@user).should_receive(:test_area).once
    flexmock(Report::ResultsByTestObject).should_receive(:new).once
    
    controller.should_receive(:respond_to_formats).once
    
    get 'results_by_test_object', :test_object_ids => '1', :piorities => '1,0,-1'
  end
  
  it "should report test efficiency" do
    log_in
    flexmock(Project).should_receive(:find).and_return(
      flexmock('project', :id => 'p_id'))
    flexmock(@user).should_receive(:test_area).once
    flexmock(Report::TestEfficiency).should_receive(:new).once
    controller.should_receive(:respond_to_formats).once
    get 'test_efficiency', :test_object_ids => '1,2'
  end
  
  it "should report requirement coverage" do
    log_in
    flexmock(@user).should_receive(:test_area).once
    controller.should_receive(:get_ids).once.and_return('tobs')
    flexmock(Report::RequirementCoverage).should_receive(:new).once.with( 
      @project.id, nil, 'id', false, 'tobs')
    flexmock(controller).should_receive(:respond_to_formats).once
    get 'requirement_coverage', :sort_by => 'id'
  end
  
  it "should report bug trend" do
    log_in
    flexmock(@user).should_receive(:test_area).once.and_return(
      flexmock('test area', :id => 'ta_id'))
    flexmock(Report::BugTrend).should_receive(:new).once.with(@project.id, 'ta_id')
    get 'bug_trend'
  end
  
  it "should report workload" do
    log_in
    flexmock(Report::Workload).should_receive(:new).once.with(@project.id)
    controller.should_receive(:respond_to_formats).once
    get 'workload'
  end
end
