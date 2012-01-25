class ChangeTestSetPriorityToInteger < ActiveRecord::Migration
  def self.up
    transaction do
      remove_column :test_sets, :priority
      remove_column :test_set_versions, :priority
      add_column :test_sets, :priority, :integer, :default => 0
      add_column :test_set_versions, :priority, :integer, :default => 0
    end
  end

  def self.down
    remove_column :test_sets, :priority
    remove_column :test_set_versions, :priority
    add_column :test_sets, :priority, :string, :default => 'normal'
    add_column :test_set_versions, :priority, :string, :default => 'normal'
  end
end
