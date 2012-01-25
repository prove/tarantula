class AddCaseExecIdToStepExec < ActiveRecord::Migration
  def self.up
    remove_column :step_executions, :case_id
    remove_column :step_executions, :execution_id
    add_column :step_executions, :case_execution_id, :integer
  end

  def self.down
    remove_column :step_executions, :case_execution_id
    add_column :step_executions, :case_id, :integer
    add_column :step_executions, :execution_id, :integer
  end
end
