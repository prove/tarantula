class DurationToCaseExecutions < ActiveRecord::Migration
  def self.up
    add_column :case_executions, :duration, :integer, :default => 0
  end

  def self.down
    remove_column :case_executions, :duration
  end
end
