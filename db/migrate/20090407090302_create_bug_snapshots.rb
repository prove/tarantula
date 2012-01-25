class CreateBugSnapshots < ActiveRecord::Migration
  def self.up
    create_table :bug_snapshots do |t|
      t.integer :bug_id
      t.integer :bug_tracker_snapshot_id
      t.integer :bug_component_id
      t.integer :bug_product_id
      t.integer :bug_severity_id
      t.integer :created_by
      t.string :external_id
      t.string :priority
      t.boolean :reported_via_tarantula
      t.string :status
      t.string :summary
      t.timestamps
    end
    
  end

  def self.down
    drop_table :bug_snapshots
  end
end
