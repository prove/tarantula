class AddUrlFieldToBug < ActiveRecord::Migration
  def self.up
    add_column :bugs, :url, :string
  end

  def self.down
    remove_column :bugs, :url
  end
end
