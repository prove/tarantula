class AddCategoryIdToCase < ActiveRecord::Migration
  def self.up
    add_column :cases, :case_category_id, :integer
  end

  def self.down
    remove_column :cases, :case_category_id
  end
end
