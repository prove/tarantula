class CreateProjectsUsers < ActiveRecord::Migration
  def self.up
    create_table :projects_users, :id => false do |t|
      t.column :project_id, :integer
      t.column :user_id, :integer
    end
    add_index :projects_users, [:user_id, :project_id]
    add_index :projects_users, :project_id
  end

  def self.down
    remove_index :projects_users, :project_id
    remove_index :projects_users, :user_id
    drop_table :projects_users
  end
end
