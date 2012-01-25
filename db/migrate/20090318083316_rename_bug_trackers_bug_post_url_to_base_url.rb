class RenameBugTrackersBugPostUrlToBaseUrl < ActiveRecord::Migration
  def self.up
    rename_column :bug_trackers, :bug_post_url, :base_url
  end

  def self.down
    rename_column :bug_trackers, :base_url, :bug_post_url
  end
end
