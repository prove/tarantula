class CreateTestSets < ActiveRecord::Migration
  def self.up
    create_table :test_sets do |t|
      t.column :name, :string
    end
  end

  def self.down
    drop_table :test_sets
  end
end
