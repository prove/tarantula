require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require "#{Rails.root}/lib/attsets/spec/shared/attachment_host_spec"


describe TestObject do
  
  def get_instance(atts={})
    TestObject.make!(atts)
  end
  
  it_behaves_like "attachment host"
  it_behaves_like "taggable"
  it_behaves_like "date stamped"
  
  it "#to_data should return required data" do
    keys = TestObject.new(:name => 'to', :project => Project.new).to_data.keys
    keys.should include(:name)
    keys.should include(:id)
    keys.should include(:date)
    keys.should include(:esw)
    keys.should include(:swa)
    keys.should include(:hardware)
    keys.should include(:mechanics)
    keys.should include(:description)
    keys.should include(:deleted)
    keys.should include(:archived)
    keys.should include(:tag_list)
    keys.should include(:test_area_ids)
    keys.size.should == 12
  end
  
  it "#to_tree should return required data" do
    keys = TestObject.new(:name => 'to').to_tree.keys
    keys.should include(:text)
    keys.should include(:dbid)
    keys.should include(:cls)
    keys.should include(:deleted)
    keys.should include(:archived)
    keys.should include(:tags)
    keys.size.should == 6
  end
  
  it "#to_s should return name" do
    TestObject.new(:name => 'to').to_s.should == 'to'
  end
  
  it ".create_with_tags should call create! and tag_with" do
    to = flexmock('test object')
    flexmock(TestObject).should_receive(:create!).once.with({'att1' => 'val1'}).\
      and_return(to)
    to.should_receive(:tag_with).once.with('tags')
    TestObject.create_with_tags({'att1' => 'val1'}, 'tags')
  end
  
  it "#update_with_tags should call update_attributes! and tag_with" do
    to = flexmock(TestObject.make!)
    to.should_receive(:update_attributes!).once.with({'att1' => 'val1'})
    to.should_receive(:tag_with).once.with('tags')
    to.update_with_tags({'att1' => 'val1'}, 'tags')
  end
  
  describe "#requirements" do
    it "should return requirements with date less than or equal" do
      p = Project.make!
      to = TestObject.make!(:project => p, :date => Date.today)
      req1 = Requirement.make!(:project => p, :date => Date.today-10)
      req2 = Requirement.make!(:project => p, :date => Date.today)
      req3 = Requirement.make!(:project => p, :date => Date.today+1)
      to.requirements.should == [req1,req2]
    end
    
    it "should select the highest version from req where updated_at < test object's date" do
      p = Project.make!
      to = TestObject.make!(:project => p, :date => Date.today-1)
      req = Requirement.make!(:project => p, :date => Date.today-10, 
                                       :updated_at => 5.days.ago.to_date)
      req.version.should == 1
      req.update_attributes!({:name => 'name change'})
      req.version.should == 2
      to.requirements.first.version.should == 1
    end
    
  end
  
end
