class CreatePasswordResets < ActiveRecord::Migration
  def self.up
    create_table :password_resets do |t|
      t.string :link
      t.boolean :activated, :default => false
      t.integer :user_id
      t.timestamps
    end
  end

  def self.down
    drop_table :password_resets
  end
end
