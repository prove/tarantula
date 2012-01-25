require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe TestArea do
  it "#to_data should return necessary data" do
    keys = TestArea.new.to_data.keys
    keys.should include(:id)
    keys.should include(:name)
    keys.should include(:bug_products)
    keys.size.should == 3
  end
  
  it "#to_tree should return necessary data" do
    keys = TestArea.new.to_tree.keys
    keys.should include(:text)
    keys.should include(:dbid)
    keys.should include(:leaf)
    keys.should include(:cls)
    keys.size.should == 4
  end
  
  describe "#current_test_object" do
    it "should return nil if no executions" do
      ta = TestArea.new
      ta.current_test_object.should == nil
    end
  end
  
end
