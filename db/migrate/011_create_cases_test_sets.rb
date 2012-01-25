class CreateCasesTestSets < ActiveRecord::Migration
  def self.up
    create_table :cases_test_sets, :id => false do |t|
      t.column :case_id, :integer
      t.column :test_set_id, :integer
    end
    add_index :cases_test_sets, [:test_set_id, :case_id]
    add_index :cases_test_sets, :case_id
  end

  def self.down
    remove_index :cases_test_sets, :case_id
    remove_index :cases_test_sets, :test_set_id
    drop_table :cases_test_sets
  end
end
