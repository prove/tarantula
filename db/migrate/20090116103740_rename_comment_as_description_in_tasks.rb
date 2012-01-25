class RenameCommentAsDescriptionInTasks < ActiveRecord::Migration
  def self.up
    rename_column :tasks, :comment, :description
  end

  def self.down
    rename_column :tasks, :description, :comment
  end
end
