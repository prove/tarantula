class AddCaseIdToStepExecutions < ActiveRecord::Migration
  def self.up
    add_column :step_executions, :case_id, :integer
  end

  def self.down
    remove_column :step_executions, :case_id
  end
end
