class AddIndexes < ActiveRecord::Migration
  def self.up
    add_index( :case_categories, :parent_id) 
    add_index( :case_categories, :project_id) 
    
    add_index( :case_executions, :case_id) 
    add_index( :case_executions, :execution_id) 
    add_index( :case_executions, :case_version)
    add_index( :case_executions, :executed_by)
    
    add_index( :case_versions, :case_id)
    add_index( :case_versions, :version)
    
    add_index( :cases, :id)
    add_index( :cases, :case_category_id)
    add_index( :cases, :project_id)
    add_index( :cases, :deleted)
    
    add_index( :cases_test_sets, :case_id)
    add_index( :cases_test_sets, :test_set_id)
    add_index( :cases_test_sets, :test_set_version)
    add_index( :cases_test_sets, :test_case_version)
    
    add_index( :executions, :id)
    add_index( :executions, :test_set_id)
    add_index( :executions, :test_set_version)
    add_index( :executions, :deleted)
    
    add_index( :step_executions, :step_id)
    add_index( :step_executions, :case_execution_id)
    
    add_index( :step_versions, :step_id)
    add_index( :step_versions, :case_id)
    
    add_index( :steps, :case_id)
    
    add_index( :taggings, :tag_id)
    add_index( :taggings, :taggable_id)
    add_index( :taggings, :taggable_type)
    
    add_index( :tags, :id)
    
    add_index( :test_set_versions, :test_set_id)
    
    add_index( :test_sets, :project_id)
    
    
  end

  def self.down
    remove_index( :case_categories, :parent_id) 
    remove_index( :case_categories, :project_id) 
    
    remove_index( :case_executions, :case_id) 
    remove_index( :case_executions, :execution_id) 
    remove_index( :case_executions, :case_version)
    remove_index( :case_executions, :executed_by)
    
    remove_index( :case_versions, :case_id)
    remove_index( :case_versions, :version)
    
    remove_index( :cases, :id)
    remove_index( :cases, :case_category_id)
    remove_index( :cases, :project_id)
    remove_index( :cases, :deleted)
    
    remove_index( :cases_test_sets, :case_id)
    remove_index( :cases_test_sets, :test_set_id)
    remove_index( :cases_test_sets, :test_set_version)
    remove_index( :cases_test_sets, :test_case_version)
    
    remove_index( :executions, :id)
    remove_index( :executions, :test_set_id)
    remove_index( :executions, :test_set_version)
    remove_index( :executions, :deleted)
    
    remove_index( :step_executions, :step_id)
    remove_index( :step_executions, :case_execution_id)
    
    remove_index( :step_versions, :step_id)
    remove_index( :step_versions, :case_id)
    
    remove_index( :steps, :case_id)
    
    remove_index( :taggings, :tag_id)
    remove_index( :taggings, :taggable_id)
    remove_index( :taggings, :taggable_type)
    
    remove_index( :tags, :id)
    
    remove_index( :test_set_versions, :test_set_id)
    
    remove_index( :test_sets, :project_id)
    
  end
end