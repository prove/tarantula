
shared_examples_for "cacheable report" do
  
  it "#to_data should not raise" do
    get_instance.to_data
  end
  
  it "should set @name in initialize" do
    report = get_instance    
    report.instance_variable_get("@name").should_not be_blank
  end
  
  it "should set @options in initialize" do
    report = get_instance    
    report.instance_variable_get("@options").should_not be_blank
  end
  
  it "should always have same cache_key if same options" do
    i = get_instance(:static => true)
    i2 = get_instance(:static => true)
    i.cache_key.should == i2.cache_key
  end

end
