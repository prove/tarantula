class AddVersionInfo < ActiveRecord::Migration
  def self.up
    # Default values for versions are 1 so unversioned database
    # can be migrated properly without breaking the references.
    add_column :cases_test_sets, :version, :integer, {:default => 1}
    add_column :cases_test_sets, :test_set_version, :integer, {:default => 1}
    add_column :cases_test_sets, :test_case_version, :integer, {:default => 1}

    add_column :cases, :version, :integer, {:default => 1}
    Case.create_versioned_table

    add_column :test_sets, :version, :integer, {:default => 1}
    TestSet.create_versioned_table
 
    add_column :executions, :test_set_version, :integer, {:default => 1}
  end

  def self.down
    remove_column :cases_test_sets, :version
    remove_column :cases_test_sets, :test_set_version
    remove_column :cases_test_sets, :test_case_version

    Case.drop_versioned_table
    remove_column :cases, :version

    TestSet.drop_versioned_table
    remove_column :test_sets, :version

    remove_column :executions, :test_set_version
  end
end
