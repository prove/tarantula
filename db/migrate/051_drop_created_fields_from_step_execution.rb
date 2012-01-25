class DropCreatedFieldsFromStepExecution < ActiveRecord::Migration
  # Move updated_at and updated_by from step_executions
  # to case_executions level. (Whole case is updated at once).
  
  def self.up
    remove_column :step_executions, :created_at
    remove_column :step_executions, :created_by    
  end

  def self.down
    add_column :step_executions, :created_at, :timestamp
    add_column :step_executions, :created_by, :integer
  end  
  
end
