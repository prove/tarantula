require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Attachment do

  it "should try to create the directory" do
    flexmock(File).should_receive(:open).once
    flexmock(FileUtils).should_receive(:mkdir_p).with(Attachment::FILE_PATH).once
    a = Attachment.create(:file_data => ['fname', flexmock('file_data')])
  end
  
  it "should save the file" do
    flexmock(FileUtils).should_receive(:mkdir_p).once
    flexmock(File).should_receive(:open).once
    a = Attachment.create(:file_data => ['fname', flexmock('file_data')])
  end
  
end
