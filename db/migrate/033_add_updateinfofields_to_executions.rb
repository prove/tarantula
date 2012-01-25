class AddUpdateinfofieldsToExecutions < ActiveRecord::Migration
  def self.up
    add_column :executions, :updated_at, :timestamp
    add_column :executions, :updated_by, :integer
  end

  def self.down
    remove_column :executions, :updated_by
    remove_column :executions, :updated_at
  end
end
