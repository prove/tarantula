class AddFieldsToTestSets < ActiveRecord::Migration
  def self.up
    add_column :test_sets, :created_at, :timestamp
    add_column :test_sets, :created_by, :integer
    add_column :test_sets, :updated_at, :timestamp
    add_column :test_sets, :updated_by, :integer
  end

  def self.down
    remove_column :test_sets, :created_at
    remove_column :test_sets, :created_by
    remove_column :test_sets, :updated_at
    remove_column :test_sets, :updated_by
  end
end
