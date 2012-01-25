class AddVersionToProjectsAndUsers < ActiveRecord::Migration
  def self.up
    add_column :projects, :version, :integer, {:default => 0}
    add_column :users, :version, :integer, {:default => 0}
  end

  def self.down
    remove_column :projects, :version
    remove_column :users, :version
  end
end
