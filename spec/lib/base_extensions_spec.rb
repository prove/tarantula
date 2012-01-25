require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "lib/base_extensions" do
  describe "String#id_parts" do
    
    it "should return ["", 0] for an empty array" do
      "".id_parts.should == ["", 0]
    end
    
    it "should return ["", NUMBER] for just a number" do
      "100".id_parts.should == ["", 100]
    end
    
    it "should return [STRING, 0] for just a string" do
      "abc".id_parts.should == ['abc', 0]
    end
    
    it "should return [STRING, NUMBER] for mixed" do
      "REQ001".id_parts.should == ['REQ', 1]
    end
    
    it "should return [STRING, NUMBER] for mixed and ignore the rest" do
      "REQ090ABC".id_parts.should == ['REQ', 90]
    end
  end
end
