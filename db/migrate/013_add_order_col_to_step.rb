class AddOrderColToStep < ActiveRecord::Migration
  def self.up
    add_column :steps, :order, :integer
  end

  def self.down
    remove_column :steps, :order
  end
end
