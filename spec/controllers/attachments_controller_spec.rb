require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe AttachmentsController do

  before(:each) do
    log_in
    @mock_host = flexmock('attachment host', :class => Case, :id => 1)
    flexmock(Case).should_receive(:find).and_return(@mock_host)
  end

  describe "#create" do
    it "should create a new attachment" do
      mock_file_data = flexmock('file_data')
      mock_att = flexmock('attachment', :to_data => {'key' => 'val'})
      
      flexmock(controller).should_receive(:get_upload_filenames).once.\
        and_return(['fname'])
      
      flexmock(Attachment).should_receive(:create!).once.with(
        :file_data => ['fname',mock_file_data.to_s]).and_return(mock_att)
      @mock_host.should_receive(:attach).once.with(mock_att)
      
      post 'create', {:case_id => 1, :file_data => mock_file_data}
      
      response.should be_success
    end
    
    it "should create multiple attachments if needed" do      
      fd1 = flexmock('file_data1')
      fd2 = flexmock('file_data2')
      
      mock_file_data = [fd1, fd2]
      
      flexmock(controller).should_receive(:get_upload_filenames).once.\
        and_return(['fname1', 'fname2'])
      
      att1 = flexmock('attachment', :to_data => {'key' => 'val'})
      att2 = flexmock('attachment 2', :to_data => {'key2' => 'val2'})
      
      flexmock(Attachment).should_receive(:create!).once.with(
        :file_data => ['fname1',fd1.to_s]).and_return(att1)
      flexmock(Attachment).should_receive(:create!).once.with(
        :file_data => ['fname2',fd2.to_s]).and_return(att2)
      
      @mock_host.should_receive(:attach).once.with(att1)
      @mock_host.should_receive(:attach).once.with(att2)
      
      post 'create', {:case_id => 1, :file_data => mock_file_data}
      
      response.should be_success
    end
    
  end

  it "#index should list attachments" do
    att = flexmock('attachment', :id => 1, :to_data => {:id => 1, :name => 'foo.bar'})
    @mock_host.should_receive(:attachments).once.and_return([att])
    get 'index', :case_id => 1
    response.should be_success
  end
  
  it "#show should use send_file in tests" do
    att = flexmock('attachment', :orig_filename => 'foo', :access_path => '/bar')
    @mock_host.should_receive('attachments.find').once.with('1').and_return(att)
    flexmock(controller).should_receive(:send_file).once
    flexmock(controller).should_receive(:render).once
    get 'show', {:case_id => 1, :id => 1}
    response.should be_success
  end
  
  it "#destroy should call unattach" do
    att = flexmock('attachment', :orig_filename => 'foo', :access_path => '/bar')
    @mock_host.should_receive('attachments.find').once.with('1').and_return(att)
    @mock_host.should_receive(:unattach).once.with(att)
    delete 'destroy', {:case_id => 1, :id => 1}
    response.should be_success
  end
  
end
