require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Report::Data do
  
  it "should serialize data-field" do
    d = Report::Data.create(:project => Project.make!, :user => User.make!)
    d.update_attributes!(:data => {:foo => 'bar'})
    d.reload
    d.data.should == {:foo => 'bar'}
  end
end
