class AddAutomationTagToAutomationTools < ActiveRecord::Migration
  def change
    add_column :automation_tools, :automation_tag, :string
  end
end
