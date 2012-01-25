class ChageFlaggingsToTasks < ActiveRecord::Migration
  def self.up
    rename_table :flaggings, :tasks
    rename_column :tasks, :flag_type, :type
    rename_column :tasks, :flaggable_id, :resource_id
    rename_column :tasks, :flaggable_type, :resource_type
    add_column :tasks, :appointee_id, :integer
    add_column :tasks, :finished, :boolean, :default => false
    ActiveRecord::Base.connection.execute "UPDATE tasks SET type='ReviewTask'"
  end

  def self.down
    rename_column :tasks, :type, :flag_type
    rename_column :tasks, :resource_id, :flaggable_id
    rename_column :tasks, :resource_type, :flaggable_type
    remove_column :tasks, :appointee_id
    remove_column :tasks, :finished
    ActiveRecord::Base.connection.execute "UPDATE tasks SET flag_type='review'"
    rename_table :tasks, :flaggings    
  end
  
end
