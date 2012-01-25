class AddLatestProjectFieldToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :latest_project_id, :integer
  end

  def self.down
    remove_column :users, :latest_project_id
  end
end
