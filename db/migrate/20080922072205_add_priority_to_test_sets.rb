class AddPriorityToTestSets < ActiveRecord::Migration
  def self.up
    add_column :test_sets, :priority, :string, :default => 'normal'
    add_column :test_set_versions, :priority, :string, :default => 'normal'
  end

  def self.down
    remove_column :test_sets, :priority
    remove_column :test_set_versions, :priority
  end
end
