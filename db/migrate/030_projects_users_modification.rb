class ProjectsUsersModification < ActiveRecord::Migration
  def self.up
    drop_table :projects_users
    create_table :projects_users do |t|
      t.column :project_id, :integer, {:null => false}
      t.column :user_id, :integer, {:null => false}
      t.column :group, :string, {:limit => 14, :default => 'GUEST', :null => false}
    end
  end

  def self.down
    drop_table :projects_users
    create_table :projects_users, :id => false do |t|
      t.column :project_id, :integer, {:null => false}
      t.column :user_id, :integer, {:null => false}
      t.column :group, :string, {:limit => 14, :default => 'GUEST', :null => false}
    end
    add_index :projects_users, [:user_id, :project_id]
    add_index :projects_users, :project_id
  end
end
