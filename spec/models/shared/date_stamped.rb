
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "date stamped", :shared => true do
  it "new instance should have date" do
    i = get_instance
    i.date.should be_kind_of(Date)
  end
  
  it "should validate presence of date" do
    i = get_instance
    i.date = nil
    i.save
    i.errors.on(:date).should_not be_nil
  end
  
end

