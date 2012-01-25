class AddDefaultTagForcedAttributeToProjectAssignments < ActiveRecord::Migration
  def self.up
    add_column :project_assignments, :default_tag_forced, :boolean, \
               :default => false
  end

  def self.down
    remove_column :project_assignments, :default_tag_forced
  end
end
