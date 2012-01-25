require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe TestSetsController do
  describe "#index" do
    it "should list test sets for project" do
      log_in
      ts = flexmock('test set', :id => 1)
      controller.should_receive(:get_tagged_items).once.with(TestSet, Hash)
      
      get 'index', {:project_id => 1}
    end
    
    it "should call get_tagged_items if tags given" do
      log_in
      flexmock(controller).should_receive(:get_tagged_items).with(TestSet).once
      get 'index', {:nodes => '3'}
    end    
  end
  
  it "#create should create a new test set" do
    log_in
    ts = flexmock('test set', :attributes => {}, :id => 1)
    flexmock(TestSet).should_receive(:create_with_cases!).once.\
      with(Hash, [1], 'a_tag').and_return(ts)
    
    post 'create', {:data => {:cases => [1], :tag_list => 'a_tag'}.to_json}
  end
  
  it "#show should show one test set" do
    log_in
    ts = flexmock('test set')
    ts.should_receive(:to_data).with(:brief).once
    flexmock(TestSet).should_receive(:find).once.and_return(ts)
    get 'show', {:id => 1}
  end
  
  it "#destroy should set deleted attribute to true" do
    log_in
    ts = flexmock('test set', :deleted => false, :id => 1)
    ts.should_receive(:deleted=).with(true).once
    ts.should_receive(:archived=).with(false).once
    ts.should_receive(:save_without_revision!).once
    flexmock(TestSet).should_receive(:find).once.and_return(ts)
    delete 'destroy', {:id => 1}
  end
  
  it "#update should update test sets info" do
    log_in
    ts = flexmock('test set', :attributes => {}, :id => 1)
    flexmock(TestSet).should_receive(:find).once.and_return(ts)
    ts.should_receive(:update_with_cases!).once.with(
      Hash, [1], 'a_tag')
    put 'update', {:id => 1, :data => {:cases => [1], :tag_list => 'a_tag'}.to_json}
  end
  
end
