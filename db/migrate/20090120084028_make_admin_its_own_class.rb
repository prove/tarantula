class MakeAdminItsOwnClass < ActiveRecord::Migration
  def self.up
    add_column :users, :type, :string, :default => 'User'
    User.connection.update "update users set type='Admin' where admin=1"
    remove_column :users, :admin
  end

  def self.down
    add_column :users, :admin, :boolean, :default => false
    User.connection.update "update users set admin=1 where type='Admin'"
    remove_column :users, :type
  end
end
