class AddPositionToCaseExecutions < ActiveRecord::Migration
  def self.up
    add_column :case_executions, :position, :integer, {:default => 0}
    add_column :step_executions, :position, :integer, {:default => 0}
  end

  def self.down
    remove_column :case_executions, :position
    remove_column :step_executions, :position
  end
end
