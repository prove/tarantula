require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe StepExecution do
  
  it "#to_data should have necessary fields" do
    se = StepExecution.make!(:step => Step.make!,
                             :case_execution => CaseExecution.make!)
    
    data = se.to_data
    data.should have_key(:id)
    data.should have_key(:step_id)
    data.should have_key(:order)
    data.should have_key(:action)
    data.should have_key(:stepresult)
    data.should have_key(:history)
    data.should have_key(:version)
    data.should have_key(:result)
    data.should have_key(:comment)
    data.should have_key(:bug)
    data.keys.size.should == 10
  end
  
end
