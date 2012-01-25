class VersioninfoToSteps < ActiveRecord::Migration
  def self.up
    add_column :steps, :version, :integer
    add_column :steps, :created_at, :timestamp
    add_column :steps, :updated_at, :timestamp
    Step.create_versioned_table
  end

  def self.down
    Step.drop_versioned_table
    remove_column :steps, :version
    remove_column :steps, :created_at
    remove_column :steps, :updated_at
  end
end
