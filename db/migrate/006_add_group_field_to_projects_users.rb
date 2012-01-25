class AddGroupFieldToProjectsUsers < ActiveRecord::Migration
  def self.up
    add_column :projects_users, :group, :string, {:limit => 14, :default => 'GUEST', :null => false}
  end

  def self.down
    remove_column :projects_users, :group
  end
end
