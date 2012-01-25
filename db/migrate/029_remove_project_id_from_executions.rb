class RemoveProjectIdFromExecutions < ActiveRecord::Migration
  def self.up
    remove_column :executions, :project_id
  end

  def self.down
    add_column :executions, :project_id, :integer
  end
end
