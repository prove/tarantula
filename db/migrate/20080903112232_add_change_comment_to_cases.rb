class AddChangeCommentToCases < ActiveRecord::Migration
  def self.up
    add_column :cases, :change_comment, :string, :default => ''
    add_column :case_versions, :change_comment, :string, :default => ''
    execute "UPDATE case_versions SET change_comment='created' WHERE version=1"
  end

  def self.down
    remove_column :cases, :change_comment
    remove_column :case_versions, :change_comment
  end
  
end
