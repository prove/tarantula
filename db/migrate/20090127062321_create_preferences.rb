class CreatePreferences < ActiveRecord::Migration
  def self.up
    create_table :preferences do |t|
      t.string  :type
      t.integer :user_id
      t.integer :project_id
      t.text    :data
    end
  end

  def self.down
    drop_table :preferences
  end
end
