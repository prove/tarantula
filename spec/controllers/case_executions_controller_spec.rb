require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe CaseExecutionsController do

  it "#index should list case_executions for an executions" do
    log_in
    mock_exec = flexmock('execution')
    mock_exec.should_receive(:case_executions).once.and_return([])
    flexmock(Execution).should_receive(:find).with(["1"]).once.and_return(mock_exec)
    get 'index', {:execution_id => 1}
  end
  
  it "#show should return data for a case execution" do
    log_in
    mock_case = flexmock('case', :to_data => {})
    mock_ce = flexmock('case_execution', :versioned_test_case => mock_case,
                       'step_executions.collect' => 'step execs',
                       :execution => flexmock('execution', :id => 1), 
                       :duration => 0)
    
    controller.should_receive(:test_area_permissions).once
    flexmock(CaseExecution).should_receive(:find).once.and_return(mock_ce)
    get 'show', {:id => 1}
  end
  
  it "#update should update" do
    log_in
    data = { 'duration' => 1,
      'step_executions' => [{'id' => 1, 
                            'result' => 'PASSED',  
                            'comment' => 'com'}]}
    mock_ce = flexmock('case execution', :id => 1, :executed_at= => nil,
                       :executed_by= => nil, :duration= => nil,
                       :update_result => nil, :result => Failed, :duration => 1,
                       'execution.long_name' => 'ELN')
    mock_ce.should_receive(:update_with_steps!).once.with({'duration' => 1},
      [{'id' => 1, 'result' => 'PASSED', 'comment' => 'com'}],
      @user)
    mock_exec = flexmock('execution', 'case_executions.find' => mock_ce)
    flexmock(Execution).should_receive(:find).once.and_return(mock_exec)
    put 'update', {:execution_id => 1, :id => 1, :data => data.to_json}
  end

  it "#destroy should call destroy on case execution" do
    log_in
    ce = flexmock('case exec', :id => 5)
    flexmock(CaseExecution).should_receive(:find).once.and_return(ce)
    ce.should_receive(:destroy_if_not_last).once
    delete 'destroy', {:id => 5}
  end

end
