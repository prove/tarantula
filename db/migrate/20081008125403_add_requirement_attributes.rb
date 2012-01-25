class AddRequirementAttributes < ActiveRecord::Migration
  def self.up
    add_column :requirements, :created_by, :integer
    add_column :requirements, :external_modified_on, :date
  end

  def self.down
    remove_column :requirements, :created_by
    remove_column :requirements, :external_modified_on
  end
end
