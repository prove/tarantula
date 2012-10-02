class CreateAutomationTools < ActiveRecord::Migration
  def change
    create_table :automation_tools do |t|
      t.string :name
      t.string :command_pattern

      t.timestamps
    end
  end
end
