class AddTestObjectToProjectAssignments < ActiveRecord::Migration
  def self.up
    add_column :project_assignments, :test_object_id, :integer
  end

  def self.down
    remove_column :project_assignments, :test_object_id
  end
end
