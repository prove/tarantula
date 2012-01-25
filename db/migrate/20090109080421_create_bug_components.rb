class CreateBugComponents < ActiveRecord::Migration
  def self.up
    create_table :bug_components do |t|
      t.string :name
      t.string :external_id
      t.integer :bug_product_id
      t.timestamps
    end
    
    add_column :bugs, :bug_component_id, :integer
    add_column :bug_trackers, :last_fetched, :datetime, :default => '1900-01-01 00:00:00'
    
    BugTracker.all.each do |bt|
      bt.refresh!
      bt.fetch_bugs(:force_update => true)
    end
  end

  def self.down
    drop_table :bug_components
    remove_column :bugs, :bug_component_id
    remove_column :bug_trackers, :last_fetched
  end
end
