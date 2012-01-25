class AddArchivedBooleanToResources < ActiveRecord::Migration
  def self.up
    add_column :executions, :archived, :boolean, :default => false
    add_column :test_objects, :archived, :boolean, :default => false
    
    add_column :test_sets, :archived, :boolean, :default => false
    add_column :test_set_versions, :archived, :boolean, :default => false
    
    add_column :requirements, :archived, :boolean, :default => false
    add_column :requirement_versions, :archived, :boolean, :default => false
    
    add_column :cases, :archived, :boolean, :default => false
    add_column :case_versions, :archived, :boolean, :default => false
  end

  def self.down
    remove_column :executions, :archived
    remove_column :test_objects, :archived
    
    remove_column :test_sets, :archived
    remove_column :test_set_versions, :archived
    
    remove_column :requirements, :archived
    remove_column :requirement_versions, :archived
    
    remove_column :cases, :archived
    remove_column :case_versions, :archived
  end
end
