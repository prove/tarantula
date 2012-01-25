class AddFieldsToCaseCategories < ActiveRecord::Migration
  def self.up
    add_column :case_categories, :name, :string
    add_column :case_categories, :parent_id, :integer
  end

  def self.down
    remove_column :case_categories, :parent_id
    remove_column :case_categories, :name
  end
end
