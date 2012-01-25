class AddDeletedToRequirements < ActiveRecord::Migration
  def self.up
    add_column :requirements, :deleted, :boolean, :default => false
  end

  def self.down
    remove_column :requirements, :deleted
  end
end
