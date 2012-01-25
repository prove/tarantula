class AddMissingFieldsToTestObjects < ActiveRecord::Migration
  
  def self.up
    add_column :test_objects, :esw, :string
    add_column :test_objects, :swa, :string
    add_column :test_objects, :hardware, :string
    add_column :test_objects, :mechanics, :string
    add_column :test_objects, :description, :text
  end

  def self.down
    remove_column :test_objects, :esw
    remove_column :test_objects, :swa
    remove_column :test_objects, :hardware
    remove_column :test_objects, :mechanics
    remove_column :test_objects, :description
  end
end
