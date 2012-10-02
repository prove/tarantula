require 'spec_helper'

describe "automation_tools/show" do
  before(:each) do
    @automation_tool = assign(:automation_tool, stub_model(AutomationTool,
      :name => "Name",
      :command_pattern => "Command Pattern"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    rendered.should match(/Command Pattern/)
  end
end
