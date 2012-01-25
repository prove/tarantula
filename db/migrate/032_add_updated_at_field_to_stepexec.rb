class AddUpdatedAtFieldToStepexec < ActiveRecord::Migration
  def self.up
    add_column :step_executions, :updated_at, :timestamp
    add_column :step_executions, :updated_by, :integer
  end

  def self.down
    remove_column :step_executions, :updated_at
    remove_column :step_executions, :updated_by
  end
end
