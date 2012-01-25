class AddSomeMissingIndices < ActiveRecord::Migration
  def self.up
    add_index :case_executions, :result
    add_index :executions, :project_id
  end

  def self.down
    remove_index :case_executions, :result
    remove_index :executions, :project_id
  end
end
