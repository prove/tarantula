class AddExecutionIds < ActiveRecord::Migration
  def self.up
    add_column :step_executions, :execution_id, :integer
    add_column :case_executions, :execution_id, :integer
  end

  def self.down
    remove_column :case_executions, :execution_id
    remove_column :step_executions, :execution_id
  end
end
