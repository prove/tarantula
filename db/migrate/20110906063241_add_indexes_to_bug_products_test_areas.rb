class AddIndexesToBugProductsTestAreas < ActiveRecord::Migration
  def self.up
    add_index :bug_products_test_areas, [:bug_product_id, :test_area_id]
  end

  def self.down
    remove_index :bug_products_test_areas, [:bug_product_id, :test_area_id]
  end
end
