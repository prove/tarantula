
shared_examples_for "task" do
  
  it "should respond to #item_class" do
    ic = get_instance.item_class
    ic.should be_kind_of(String)
  end
  
  it "should respond to #item_name" do
    iname = get_instance.item_name
    iname.should be_kind_of(String)
  end
  
  it "should respond to #link" do
    get_instance.should respond_to(:link)
  end
  
  it "should respond to #finished?" do
    get_instance.should respond_to(:finished?)
  end
  
  it "should respond to #name" do
    get_instance.should respond_to(:name)
  end
  
  it "#to_data should contain necessary data" do
    i = get_instance
    if i.class != Task::Execution 
      keys = get_instance.to_data.keys
      keys.should include(:id)
      keys.should include(:project_id)
      keys.should include(:name)
      keys.should include(:finished)
      keys.should include(:finished_at)
      keys.should include(:description)
      keys.should include(:assigned_to)
      keys.should include(:assignee)
      keys.should include(:resource_type)
      keys.should include(:resource_id)
      keys.should include(:created_by)
      keys.should include(:creator)
      keys.should include(:link)
      keys.size.should == 13
    end
  end
  
end

