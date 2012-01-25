class ChangesToTasks < ActiveRecord::Migration
  def self.up
    rename_column :tasks, :appointee_id, :assigned_to
    add_column :tasks, :project_id, :integer
    change_column :tasks, :comment, :text
  end

  def self.down
    rename_column :tasks, :assigned_to, :appointee_id
    remove_column :tasks, :project_id
    change_column :tasks, :comment, :string
  end
end
