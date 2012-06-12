
shared_examples_for "externally_identifiable" do
  
  it "should have external_id attribute" do
    get_instance.attributes.keys.should include('external_id')
  end
  
  it "should validate uniqueness of external_id properly" do
    i = get_instance
    scope = i.class.external_id_scope
    start_count = i.class.count - 1
    i.destroy
    sc1 = scope.to_s.classify.constantize.send(:make!)
    sc2 = scope.to_s.classify.constantize.send(:make!)
    i1 = get_instance(:external_id => 'e1', scope => sc1)
    i2 = get_instance(:external_id => 'e2', scope => sc2)
    i1.class.count.should == start_count + 2
    
    i3 = get_instance(:external_id => 'e1', scope => sc2)
    i1.class.count.should == start_count + 3
    
    lambda { get_instance(:external_id => 'e1', scope => sc2)}.should \
      raise_error(ActiveRecord::RecordInvalid)
  end
  
end

