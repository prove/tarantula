require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe CaseExecution do
  it "should create a new instance given valid attributes" do
    CaseExecution.make!
  end

  it ".create_with_steps should create a case execution for a case of " +
     "an execution" do
    p = Project.make_with_cases(:cases => 1)
    ts = TestSet.make!(:project => p)
    case1 = p.cases.first
    case1.position = 1
    ts.cases << case1
    e = Execution.make!

    ce = CaseExecution.create_with_steps!({:execution => e,
                                           :case_id => case1.id,
                                           :position => 1})
    ce.test_case.should == case1
    ce.result.should == NotRun
    ce.execution.should == e

    ce.step_executions.map{|x| x.step}.should == case1.steps
    ce.step_executions.each do |x|
      x.result.should == NotRun
    end
  end

  it "#update_with_steps should update" do
    ce = CaseExecution.make!
    se = StepExecution.make!(:case_execution => ce)

    ce.update_with_steps!({'duration' => 10},
      [{'id' => se.id, 'result' => 'PASSED', 'bug' => {:id => 1}, 'comment' => 'com'}], @user)
    se.reload.result.should == Passed
  end

  describe "#failed_steps_info" do
    it "should return nil if no failed steps" do
      p = Project.make_with_cases(:cases => 1)
      case1 = p.cases.first
      e = Execution.make!(:project => p)
      ce = CaseExecution.create_with_steps!({:execution => e,
                                             :case_id => case1.id,
                                             :position => 1})
      ce.failed_steps_info.should == nil
    end

    it "should return nil if no failed steps" do
      p = Project.make!
      case1 = Case.make!(:project => p)
      case1.steps << Step.make!(:action => 'a1', :result => 'r1',
                                :position => 1)
      case1.steps << Step.make!(:action => 'a2', :result => 'r2',
                                :position => 2)

      e = Execution.make!(:project => p)
      ce = CaseExecution.create_with_steps!({:execution => e,
                                             :case_id => case1.id,
                                             :position => 1})
      ce.step_executions << StepExecution.make!(
                              :step => case1.steps.first,
                              :position => 1,
                              :result => Failed)
      ce.step_executions << StepExecution.make!(
                              :step => case1.steps[1],
                              :position => 2,
                              :result => Failed)

      ce.failed_steps_info.should == "FAILED: step 1, #{case1.steps[0].action}; "+
                                     "step 2, #{case1.steps[1].action}"
    end
  end

  describe "#update_case_version" do
    it "should update case reference" do
      ce = CaseExecution.make!
      updater = User.make!
      c = ce.test_case
      c.version.should == 1
      c.update_attributes! :name => "New name"
      c.version.should == 2
      flexmock(ce).should_receive(:update_result)

      ce.update_case_version(2, updater)
      ce.reload.test_case.name.should == "New name"
    end

    it "should update step references" do
      ce = CaseExecution.make!
      updater = User.make!
      c = ce.test_case
      c.version.should == 1
      c.update_attributes! :name => "New name"
      c.version.should == 2
      c.steps << Step.new(:action => 'aaa', :result => 'r', :position => 1)
      flexmock(ce).should_receive(:update_result)

      ce.update_case_version(2, updater)
      ce.step_executions.first.step.action.should == 'aaa'
    end

    it "should keep results of updated step references" do
      ce = CaseExecution.make!
      updater = User.make!
      c = ce.test_case
      c.steps << Step.new(:action => 'a', :result => 'b', :position => 1)
      ce.step_executions.create!(:step_id => c.steps.first.id,
                                 :step_version => 1)
      ce.step_executions.first.update_attribute(:result, Passed)
      step = ce.step_executions.first.step
      step.update_attribute(:action, 'argh')
      step.position = 1

      c.update_attributes! :name => "New name"
      c.steps << step

      flexmock(ce).should_receive(:update_result)

      ce.update_case_version(2, updater)
      ce.step_executions.first.result.should == Passed
    end
  end

  it "should update also case's update_at time when saved" do
    ce = CaseExecution.make!
    u_at = ce.test_case.updated_at
    sleep(1)
    ce.update_attributes(:assigned_to => 10)
    ce.test_case.reload.updated_at.should_not == u_at
  end

  describe "#update_result" do
    it "should not call #update_duplicates if CustomerConfig.update_duplicates not set" do
      ce = flexmock(CaseExecution.make_with_result(
                      :result => Passed, :test_case => Case.make_with_steps))
      user = User.make!
      ce.should_receive(:update_duplicates).never
      ce.update_result(user)
    end

    it "should call #update_duplicates if CustomerConfig.update_duplicates set" do
      CustomerConfig.update_duplicates = true
      ce = flexmock(CaseExecution.make_with_result(
                      :result => Passed, :test_case => Case.make_with_steps))
      user = User.make!
      ce.should_receive(:update_duplicates).once
      ce.update_result(user)
    end
  end

  describe "#update_duplicates" do
    it "should update duplicates in the same test object" do
      p = Project.make!
      tob = TestObject.make!(:project => p)
      test_case = Case.make_with_steps(:project => p)
      user = User.make!

      exec1 = Execution.make!(:project => p, :test_object => tob)
      exec2 = Execution.make!(:project => p, :test_object => tob)

      ce1 = CaseExecution.make_with_result(:result    => Passed,
                                           :execution => exec1,
                                           :test_case => test_case)

      ce2 = CaseExecution.make_with_result(:result    => Passed,
                                           :execution => exec2,
                                           :test_case => test_case)

      ce1.step_executions.first.update_attribute(:result, Failed)
      ce1.update_duplicates(user)
      ce2.reload.result.should == Failed
    end

    it "should not update duplicates on different test area than user" do
      p = Project.make!
      ta1 = TestArea.make!(:project => p)
      ta2 = TestArea.make!(:project => p)
      tob = TestObject.make!(:project => p)
      test_case = Case.make_with_steps(:project => p)
      user = User.make!
      ProjectAssignment.create!(:user => user, :project => p,
                                :group => 'TEST_ENGINEER', :test_area => ta1)

      exec1 = Execution.make!(:project => p, :test_object => tob,
                             :test_areas => [ta1])
      exec2 = Execution.make!(:project => p, :test_object => tob,
                             :test_areas => [ta2])
      exec3 = Execution.make!(:project => p, :test_object => tob,
                             :test_areas => [ta1])

      ce1 = CaseExecution.make_with_result(:result    => Passed,
                                           :execution => exec1,
                                           :test_case => test_case)

      ce2 = CaseExecution.make_with_result(:result    => Passed,
                                           :execution => exec2,
                                           :test_case => test_case)

      ce3 = CaseExecution.make_with_result(:result    => Passed,
                                           :execution => exec3,
                                           :test_case => test_case)


      ce1.step_executions.first.update_attribute(:result, Failed)
      ce1.update_duplicates(user)
      ce2.reload.result.should == Passed
      ce3.reload.result.should == Failed
    end
  end

end
