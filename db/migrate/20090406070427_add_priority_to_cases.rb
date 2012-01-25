class AddPriorityToCases < ActiveRecord::Migration
  def self.up
    add_column :cases, :priority, :integer, :default => 0
    add_column :case_versions, :priority, :integer, :default => 0
  end
  
  def self.down
    remove_column :cases, :priority
    remove_column :case_versions, :priority
  end
end
