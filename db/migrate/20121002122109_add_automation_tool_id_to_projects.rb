class AddAutomationToolIdToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :automation_tool_id, :integer
  end
end
