class CreateFlaggings < ActiveRecord::Migration
  def self.up
    create_table :flaggings do |t|
      t.string  :flag_type
      t.integer :flaggable_id
      t.string  :flaggable_type
      t.string  :comment
      t.timestamps
    end
  end

  def self.down
    drop_table :flaggings
  end
end
