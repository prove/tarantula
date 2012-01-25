class AddTestObjectForExecution < ActiveRecord::Migration
  def self.up
    add_column :executions, :test_object, :string, :default => 'unknown'
  end

  def self.down
    remove_column :executions, :test_object
  end
end
