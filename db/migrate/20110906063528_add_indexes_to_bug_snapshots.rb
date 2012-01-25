class AddIndexesToBugSnapshots < ActiveRecord::Migration
  def self.up
    change_table :bug_snapshots do |t|
      t.index :bug_id
      t.index :bug_tracker_snapshot_id
      t.index :bug_component_id
      t.index :bug_product_id
      t.index :bug_severity_id
      t.index :external_id
      t.index :priority
      t.index :status
      t.index :lastdiffed
    end
  end

  def self.down
    change_table :bug_snapshots do |t|
      t.remove_index :bug_id
      t.remove_index :bug_tracker_snapshot_id
      t.remove_index :bug_component_id
      t.remove_index :bug_product_id
      t.remove_index :bug_severity_id
      t.remove_index :external_id
      t.remove_index :priority
      t.remove_index :status
      t.remove_index :lastdiffed
    end
  end
end
