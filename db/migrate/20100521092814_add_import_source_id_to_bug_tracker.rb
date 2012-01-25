class AddImportSourceIdToBugTracker < ActiveRecord::Migration
  def self.up
    add_column :bug_trackers, :import_source_id, :integer
  end

  def self.down
    remove_column :bug_trackers, :import_source_id
  end
end
