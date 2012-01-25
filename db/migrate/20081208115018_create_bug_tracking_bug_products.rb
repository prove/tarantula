class CreateBugTrackingBugProducts < ActiveRecord::Migration
  def self.up
    create_table :bug_products do |t|      
      t.timestamps
      t.string :name
      t.integer :bug_tracker_id
      t.string :external_id
    end
    
    drop_table :bug_tracker_configs
    
    # habtm
    create_table :bug_products_projects, :id => false do |t|
      t.integer :bug_product_id
      t.integer :project_id
    end
    
    add_column :projects, :bug_tracker_id, :integer
    add_column :test_areas, :bug_product_id, :integer
    rename_column :bugs, :product_id, :bug_product_id
  end
  
  def self.down
    drop_table :bug_products
    drop_table :bug_products_projects
    create_table :bug_tracker_configs do |t|
      t.integer :project_id
      t.integer :bug_tracker_id
      t.string :product_ids
    end
    
    remove_column :projects, :bug_tracker_id
    remove_column :test_areas, :bug_product_id
    rename_column :bugs, :bug_product_id, :product_id
  end
end
