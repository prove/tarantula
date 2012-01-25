class AddProjectIdForeignKeyFields < ActiveRecord::Migration
  def self.up
    add_column :cases, :project_id, :integer
    add_column :test_sets, :project_id, :integer
    add_column :executions, :project_id, :integer
    add_column :case_categories, :project_id, :integer
  end

  def self.down
    remove_column :cases, :project_id
    remove_column :test_sets, :project_id
    remove_column :executions, :project_id
    remove_column :case_categories, :project_id
  end
end
