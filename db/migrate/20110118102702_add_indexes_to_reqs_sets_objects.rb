# Additional indexes to Requirements, Test Sets and Test Objects
class AddIndexesToReqsSetsObjects < ActiveRecord::Migration
  def self.up
    change_table :requirements do |t|
      t.index :project_id
      t.index :external_id
      t.index :name
    end
    change_table :test_objects do |t|
      t.index :project_id
      t.index :name
    end
    add_index :test_sets, [:priority, :name]
  end

  def self.down
    change_table :requirements do |t|
      t.remove_index :project_id
      t.remove_index :external_id
      t.remove_index :name
    end
    change_table :test_objects do |t|
      t.remove_index :project_id
      t.remove_index :name
    end
    remove_index :test_sets, [:priority, :name]
  end
end
