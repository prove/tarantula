class AddIndexesToBugs < ActiveRecord::Migration
  def self.up
    change_table :bugs do |t|
      t.index :bug_tracker_id
      t.index :bug_severity_id
      t.index :external_id
      t.index :bug_product_id
      t.index :bug_component_id
      t.index :status
      t.index :priority
      t.index :lastdiffed
    end
  end

  def self.down
    change_table :bugs do |t|
      t.remove_index :bug_tracker_id
      t.remove_index :bug_severity_id
      t.remove_index :external_id
      t.remove_index :bug_product_id
      t.remove_index :bug_component_id
      t.remove_index :status
      t.remove_index :priority
      t.remove_index :lastdiffed
    end
  end
end
