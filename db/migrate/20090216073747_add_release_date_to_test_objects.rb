class AddReleaseDateToTestObjects < ActiveRecord::Migration
  def self.up
    add_column :test_objects, :release_date, :date
  end

  def self.down
    remove_column :test_objects, :release_date
  end
end
