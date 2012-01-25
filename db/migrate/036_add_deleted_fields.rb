class AddDeletedFields < ActiveRecord::Migration
  def self.up
    add_column :projects, :deleted, :boolean, {:default => false}
    # remove obsolete visible -field.
    remove_column :projects, :visible
    add_column :cases, :deleted, :boolean, {:default => false}
    add_column :case_versions, :deleted, :boolean, {:default => false}
    add_column :test_sets, :deleted, :boolean, {:default => false}
    add_column :test_set_versions, :deleted, :boolean, {:default => false}
    add_column :executions, :deleted, :boolean, {:default => false}
    add_column :users, :deleted, :boolean, {:default => false}
  end

  def self.down
    remove_column :projects, :deleted
    add_column :projects, :visible, :boolean, {:default => true}
    remove_column :cases, :deleted
    remove_column :case_versions, :deleted
    remove_column :test_sets, :deleted
    remove_column :test_set_versions, :deleted
    remove_column :executions, :deleted
    remove_column :users, :deleted
  end
end
