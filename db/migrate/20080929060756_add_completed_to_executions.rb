class AddCompletedToExecutions < ActiveRecord::Migration
  
  def self.up
    add_column :executions, :completed, :boolean, :default => false
  end

  def self.down
    remove_column :executions, :completed
  end
  
end
