class AddProductIdToBugs < ActiveRecord::Migration
  def self.up
    Bug.destroy_all
    add_column :bugs, :product_id, :integer
  end

  def self.down
    remove_column :bugs, :product_id
  end
end
