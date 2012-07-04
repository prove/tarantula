require "spec_helper"

shared_examples_for "attachment host" do
  
  it "should return empty array when no attachments" do
    @host = get_instance
    @host.attachments.should == []
  end
  
  it "#attach should add an attachment" do
    @host = get_instance
    a = Attachment.make!
    @host.all_attachment_sets.size.should == 0
    @host.attach(a)
    @host.reload.attachments.should include(a)
    @host.all_attachment_sets.size.should == 1
  end
  
  it "#unattach should remove an attachment" do
    @host = get_instance
    a1 = Attachment.make!
    @host.attach(a1)
    @host.reload.attachments.should include(a1)
    @host.unattach(a1)
    
    @host.reload.attachments.should_not include(a1)
    @host.all_attachment_sets.size.should == 2
  end
  
  it "should handle multiple attachments" do
    @host = get_instance
    a = Attachment.make!
    a2 = Attachment.make!
    a3 = Attachment.make!
    a4 = Attachment.make!
    @host.attach(a)
    @host.attach(a2)
    @host.attach(a3)
    @host.attach(a4)
    @host.reload.all_attachment_sets.size.should == 4
    @host.attachments.should == [a,a2,a3,a4]
    @host.unattach(a2)
    @host.unattach(a)
    @host.unattach(a4)
    @host.attachments.should == [a3]
  end
  
  it "should not show attachments that don't belong to it" do
    @host = get_instance
    @host2 = get_instance
    @host3 = get_instance
    a = Attachment.make!
    a2 = Attachment.make!
    a3 = Attachment.make!
    a4 = Attachment.make!
    @host.attach(a)
    @host2.attach(a3)
    @host.attach(a2)
    @host2.attach(a4)
    @host3.attach(a)
    @host3.attach(a3)
    @host.attachments.should == [a,a2]
    @host2.attachments.should == [a3,a4]
    @host3.attachments.should == [a,a3]
  end
  
end
