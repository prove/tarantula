require 'spec_helper'

describe "AutomationTools" do
  describe "GET /automation_tools" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get automation_tools_path
      response.status.should be(200)
    end
  end
end
