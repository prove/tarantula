class MoveUpdatedFieldsToCaseExecution < ActiveRecord::Migration
  # Move updated_at and updated_by from step_executions
  # to case_executions level. (Whole case is updated at once).
  
  def self.up
    add_column :case_executions, :updated_at, :timestamp
    add_column :case_executions, :updated_by, :integer
    remove_column :step_executions, :updated_at
    remove_column :step_executions, :updated_by    
  end

  def self.down
    remove_column :case_executions, :updated_at
    remove_column :case_executions, :updated_by
  
    add_column :step_executions, :updated_at, :timestamp
    add_column :step_executions, :updated_by, :integer
  end  
  
end
