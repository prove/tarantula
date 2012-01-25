class MakeBugTrackerASuperclass < ActiveRecord::Migration
  def self.up
    add_column :bug_trackers, :type, :string, :default => 'Bugzilla'
  end

  def self.down
    remove_column :bug_tracker, :type, :string
  end
end
