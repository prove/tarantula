class AddVersionToExecutions < ActiveRecord::Migration
  def self.up
    add_column :executions, :version, :integer, {:default => 0}
  end

  def self.down
    remove_column :executions, :version
  end
end
