class CreateBugTrackerSnapshots < ActiveRecord::Migration
  def self.up
    create_table :bug_tracker_snapshots do |t|
      t.integer :bug_tracker_id
      t.timestamps
    end
  end

  def self.down
    drop_table :bug_tracker_snapshots
  end
end
