class AddDeletedFieldToTestObjects < ActiveRecord::Migration
  
  def self.up
    add_column :test_objects, :deleted, :boolean, :default => false
  end

  def self.down
    remove_column :test_objects, :deleted
  end
  
end
