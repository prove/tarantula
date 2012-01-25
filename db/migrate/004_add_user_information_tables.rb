class AddUserInformationTables < ActiveRecord::Migration
  def self.up
    add_column :users, :phone, :string
    add_column :users, :realname, :string
    add_column :users, :description, :text
  end

  def self.down
    remove_column :users, :phone
    remove_column :users, :realname
    remove_column :users, :description
  end
end
