class AddOriginalIdToCases < ActiveRecord::Migration
  def self.up
    add_column :cases, :original_id, :integer
    add_column :case_versions, :original_id, :integer
  end

  def self.down
    remove_column :cases, :original_id
    remove_column :case_versions, :original_id
  end
end
