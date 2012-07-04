require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Step do
  def get_instance; Step.make!; end
  it_behaves_like "versioned"
  
  it "#to_data should contain needed attributes" do
    data = Step.make!.to_data
    data.keys.should include(:id)
    data.keys.should include(:action)
    data.keys.should include(:result)
    data.keys.should include(:version)
    data.keys.should include(:position)
    data.keys.size.should == 5
  end
  
  describe "#update_if_needed" do
    it "should not update if nothing changed" do
      s = flexmock(Step.make!)
      s.should_receive(:save).and_raise('save should not have been called')
      s.update_if_needed(s.attributes)
      s.version.should == 1
    end
    
    it "should update if attributes changed" do
      s = Step.make!(:action => 'a1', :result => 'r1', :position => '1')
      s.version.should == 1
      s.update_if_needed(:action => 'a2', :result => 'r1', :position => '1')
      s.version.should == 2
      s.update_if_needed(:action => 'a2', :result => 'r2', :position => '1')
      s.version.should == 3
      s.update_if_needed(:action => 'a2', :result => 'r2', :position => '2')
      s.version.should == 4
    end    
  end
  
  describe "#history" do
    it "should return 3 last step executions" do
      s = Step.make!
      e = Execution.make!
      ce = CaseExecution.make!(:execution => e)
      se1 = StepExecution.make!(:step => s, :comment => '1',
                                            :case_execution => ce,
                                            :result => Passed)
      se2 = StepExecution.make!(:step => s, :comment => '2',
                                            :case_execution => ce,
                                            :result => Failed)
      se3 = StepExecution.make!(:step => s, :comment => '3',
                                            :case_execution => ce,
                                            :result => Passed)
      se4 = StepExecution.make!(:step => s, :comment => '4',
                                            :case_execution => ce,
                                            :result => Passed)
      hist = s.history
      hist[0][:comment].should == '4'
      hist[1][:comment].should == '3'
      hist[2][:comment].should == '2'
      hist.size.should == 3
    end
    
    it "should exclude the step execution given as argument" do
      s = Step.make!
      e = Execution.make!
      ce = CaseExecution.make!(:execution => e)
      se1 = StepExecution.make!(:step => s, :comment => '1',
                                            :case_execution => ce,
                                            :result =>  Passed)
      se2 = StepExecution.make!(:step => s, :comment => '2',
                                            :case_execution => ce,
                                            :result => Passed)
      se3 = StepExecution.make!(:step => s, :comment => '3',
                                            :case_execution => ce,
                                            :result => Failed)
      se4 = StepExecution.make!(:step => s, :comment => '4',
                                            :case_execution => ce,
                                            :result => Passed)
      hist = s.history(se4)
      hist[0][:comment].should == '3'
      hist[1][:comment].should == '2'
      hist[2][:comment].should == '1'
      hist.size.should == 3
    end
    
    it "should exclude not run step executions" do
        s = Step.make!
        e = Execution.make!
        ce = CaseExecution.make!(:execution => e)
        se1 = StepExecution.make!(:step => s, :comment => '1',
                                              :case_execution => ce,
                                              :result => NotRun)
        s.history.size.should == 0
    end
    
  end
  
end
