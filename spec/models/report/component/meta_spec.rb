require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe Report::Component::Meta do
  def get_instance(opts={})
    Report::Component::Meta.new(opts)
  end
  it_behaves_like "report component"
  
  it "should store arbitrary values" do
    r = get_instance
    r.foo = 'bar'
    r.baz = 'bars'
    r.foo.should == 'bar'
    r.baz.should == 'bars'
  end
end