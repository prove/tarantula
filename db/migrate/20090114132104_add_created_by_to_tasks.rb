class AddCreatedByToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :created_by, :integer
  end

  def self.down
    remove_column :tasks, :created_by
  end
end
