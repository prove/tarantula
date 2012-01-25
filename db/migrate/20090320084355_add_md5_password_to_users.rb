class AddMd5PasswordToUsers < ActiveRecord::Migration
  
  def self.up
    add_column :users, :md5_password, :string
  end

  def self.down
    remove_column :users, :md5_password
  end
  
end
