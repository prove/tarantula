require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "SmartTag" do
  
  describe "TaggingExtensions#find_with_tags integration" do
    
    it "should find AlwaysFailed" do
      p = Project.make!
      c = Case.make!(:project => p)
      c2 = Case.make!(:project => p)
      to = TestObject.make!(:project => p)
      e = Execution.make!(:project => p, :test_object => to)
      
      CaseExecution.make_with_result(:result => Passed,
                                     :execution => e,
                                     :test_case => c2)
      CaseExecution.make_with_result(:result => Failed,
                                     :execution => e,
                                     :test_case => c)
      
      Case.find_with_tags([], :project => p,
                              :smart_tags => [SmartTag::AlwaysFailed]).should == [c]
    end
    
    it "should find Failed" do
      p = Project.make!
      c = Case.make!(:project => p)
      c2 = Case.make!(:project => p)
      to = TestObject.make!(:project => p)
      e = Execution.make!(:project => p, :test_object => to)
      
      CaseExecution.make_with_result(:result => Passed,
                                     :execution => e,
                                     :test_case => c2)
      CaseExecution.make_with_result(:result => Failed,
                                     :execution => e,
                                     :test_case => c)
      
      Case.find_with_tags([], :project => p,
                              :smart_tags => [SmartTag::Failed]).should == [c]
    end
    
    it "should find NeverTested" do
      p = Project.make!
      c = Case.make!(:project => p)
      c2 = Case.make!(:project => p)
      e = Execution.make!(:project => p)
      
      CaseExecution.make_with_result(:result => Passed,
                                     :execution => e,
                                     :test_case => c2)
      
      Case.find_with_tags([], :project => p,
                              :smart_tags => [SmartTag::NeverTested]).should == [c]
    end
    
    it "should find NotImplemented" do
      p = Project.make!
      c = Case.make!(:project => p)
      c2 = Case.make!(:project => p)
      to = TestObject.make!(:project => p)
      e = Execution.make!(:project => p, :test_object => to)
      
      CaseExecution.make_with_result(:result => Passed,
                                     :execution => e,
                                     :test_case => c2)
      CaseExecution.make_with_result(:result => NotImplemented,
                                     :execution => e,
                                     :test_case => c)
      
      Case.find_with_tags([], :project => p,
                              :smart_tags => [SmartTag::NotImplemented]).should == [c]
    end
    
    it "should find Untagged" do
      p = Project.make!
      c = Case.make!(:project => p)
      c2 = Case.make!(:project => p)
      c2.tag_with('tagged')
      Case.find_with_tags([], :project => p,
                             :smart_tags => [SmartTag::Untagged]).should == [c]
    end
  end
end
