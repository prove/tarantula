require 'spec_helper'

describe "automation_tools/edit" do
  before(:each) do
    @automation_tool = assign(:automation_tool, stub_model(AutomationTool,
      :name => "MyString",
      :command_pattern => "MyString"
    ))
  end

  it "renders the edit automation_tool form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => automation_tools_path(@automation_tool), :method => "post" do
      assert_select "input#automation_tool_name", :name => "automation_tool[name]"
      assert_select "input#automation_tool_command_pattern", :name => "automation_tool[command_pattern]"
    end
  end
end
