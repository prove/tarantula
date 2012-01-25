class AddIndexesToCasesExecutionsAndTestObjects < ActiveRecord::Migration
  def self.up
    change_table :cases do |t|
      t.index [:priority, :title]
    end
    add_index :executions, :test_object_id
    change_table :test_objects do |t|
      t.index :date
      t.index :created_at
    end
  end

  def self.down
    change_table :cases do |t|
      t.remove_index [:priority, :title]
    end
    remove_index :executions, :test_object_id
    change_table :test_objects do |t|
      t.remove_index :date
      t.remove_index :created_at
    end
  end
end

