require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Preference::Dashboard do
  it "should have a .default method" do
    Preference::Dashboard.should respond_to(:default)
  end
end
