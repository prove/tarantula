class AddSyncFieldToBugTracker < ActiveRecord::Migration
  def self.up
    add_column :bug_trackers, :sync_project_with_classification, :boolean, :default => false
  end

  def self.down
    remove_column :bug_trackers, :sync_project_with_classification
  end
end
