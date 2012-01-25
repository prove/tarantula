class CreateExecutionsUsers < ActiveRecord::Migration
  def self.up
    create_table :executions_users, :id => false do |t|
      t.column :execution_id, :integer
      t.column :user_id, :integer
    end
    add_index :executions_users, [:user_id, :execution_id]
    add_index :executions_users, :execution_id
  end

  def self.down
    remove_index :executions_users, :execution_id
    remove_index :executions_users, :user_id
    drop_table :executions_users
  end
end
