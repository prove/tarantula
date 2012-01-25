class AddIndexesToBugSeverities < ActiveRecord::Migration
  def self.up
    add_index :bug_severities, :sortkey
    add_index :bug_severities, :bug_tracker_id
    add_index :bug_severities, :external_id
  end

  def self.down
    remove_index :bug_severities, :sortkey
    remove_index :bug_severities, :bug_tracker_id
    remove_index :bug_severities, :external_id
  end
end
