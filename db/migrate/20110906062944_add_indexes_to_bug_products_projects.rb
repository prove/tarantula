class AddIndexesToBugProductsProjects < ActiveRecord::Migration
  def self.up
    add_index :bug_products_projects, [:bug_product_id, :project_id]
  end

  def self.down
    remove_index :bug_products_projects, [:bug_product_id, :project_id]
  end
end
