require 'spec_helper'

describe "automation_tools/index" do
  before(:each) do
    assign(:automation_tools, [
      stub_model(AutomationTool,
        :name => "Name",
        :command_pattern => "Command Pattern"
      ),
      stub_model(AutomationTool,
        :name => "Name",
        :command_pattern => "Command Pattern"
      )
    ])
  end

  it "renders a list of automation_tools" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "Command Pattern".to_s, :count => 2
  end
end
