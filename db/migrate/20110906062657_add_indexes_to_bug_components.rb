class AddIndexesToBugComponents < ActiveRecord::Migration
  def self.up
    add_index :bug_components, :external_id
    add_index :bug_components, :bug_product_id
  end

  def self.down
    remove_index :bug_components, :external_id
    remove_index :bug_components, :bug_product_id
  end
end
