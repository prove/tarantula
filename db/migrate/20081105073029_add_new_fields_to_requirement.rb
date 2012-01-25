class AddNewFieldsToRequirement < ActiveRecord::Migration
  def self.up
    add_column :requirements, :description, :string
    add_column :requirements, :priority, :string
    add_column :requirements, :optionals, :text
  end

  def self.down
    remove_column :requirements, :description
    remove_column :requirements, :priority
    remove_column :requirements, :optionals
  end
end
