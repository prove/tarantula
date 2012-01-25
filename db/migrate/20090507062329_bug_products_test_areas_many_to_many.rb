class BugProductsTestAreasManyToMany < ActiveRecord::Migration
  def self.up
    create_table :bug_products_test_areas, :id => false do |t|
      t.integer :bug_product_id
      t.integer :test_area_id
    end
    TestArea.all.each do |ta|
      if ta.bug_product_id
        ta.bug_products << BugProduct.find(ta.bug_product_id)
      end
    end
    remove_column :test_areas, :bug_product_id
  end
  
  def self.down
    drop_table :bug_products_test_areas
    add_column :test_areas, :bug_product_id, :integer
  end
end
