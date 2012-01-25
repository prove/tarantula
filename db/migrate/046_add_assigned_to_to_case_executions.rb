class AddAssignedToToCaseExecutions < ActiveRecord::Migration
  def self.up
    add_column :case_executions, :assigned_to, :integer
  end

  def self.down
    remove_column :case_executions, :assigned_to
  end
end
