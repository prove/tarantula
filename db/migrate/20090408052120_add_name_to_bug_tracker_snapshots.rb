class AddNameToBugTrackerSnapshots < ActiveRecord::Migration
  def self.up
    add_column :bug_tracker_snapshots, :name, :string
  end

  def self.down
    remove_column :bug_tracker_snapshots, :name
  end
end
