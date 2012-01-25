require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe ArchivesController do

  describe "#create" do
    it "should archive resources" do
      log_in
      c = flexmock('case')
      c.should_receive(:archived=).once.with(true)
      c.should_receive(:deleted=).once.with(false)
      c.should_receive(:save_without_revision!).once
      flexmock(Case).should_receive(:find).once.and_return([c])
            
      post 'create', {:project_id => 1, :resources => 'cases', :ids => "1,2"}
    end
  end

  describe "#destroy" do
    it "should unarchive resources" do
      log_in
      c = flexmock('case', :deleted => false)
      c.should_receive(:archived=).once.with(false)
      c.should_receive(:deleted=).once.with(false)
      c.should_receive(:save_without_revision!).once
      flexmock(Case).should_receive(:find).once.and_return([c])
      
      delete 'destroy', {:project_id => 1, :resources => 'cases', :ids => "1,2"}
    end
  end

  
end
