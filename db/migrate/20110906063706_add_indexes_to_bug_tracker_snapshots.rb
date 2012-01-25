class AddIndexesToBugTrackerSnapshots < ActiveRecord::Migration
  def self.up
    add_index :bug_tracker_snapshots, :bug_tracker_id
  end

  def self.down
    remove_index :bug_tracker_snapshots, :bug_tracker_id
  end
end
