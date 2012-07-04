
shared_examples_for "prioritized" do
  it "should validate priority value" do
    invalid_val = Project::Priorities.map{|p| p[:value]}.max + 1
    i = get_instance
    i.priority = invalid_val
    i.save
    i.errors[:priority].should_not be_empty
  end
  
  it "#priority_name should return priority name" do
    i = get_instance
    i.priority_name.should == 'normal'
  end
end

