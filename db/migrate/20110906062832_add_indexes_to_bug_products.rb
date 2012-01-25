class AddIndexesToBugProducts < ActiveRecord::Migration
  def self.up
    add_index :bug_products, :bug_tracker_id
    add_index :bug_products, :external_id
  end

  def self.down
    remove_index :bug_products, :bug_tracker_id
    remove_index :bug_products, :external_id
  end
end
