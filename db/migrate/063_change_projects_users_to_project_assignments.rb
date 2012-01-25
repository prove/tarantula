class ChangeProjectsUsersToProjectAssignments < ActiveRecord::Migration
  def self.up
    rename_table :projects_users, :project_assignments
  end

  def self.down    
    rename_table :project_assignments, :projects_users
  end
end
