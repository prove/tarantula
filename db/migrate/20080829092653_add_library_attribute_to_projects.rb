class AddLibraryAttributeToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :library, :boolean, :default => false
  end

  def self.down
    remove_column :projects, :library
  end
  
end
