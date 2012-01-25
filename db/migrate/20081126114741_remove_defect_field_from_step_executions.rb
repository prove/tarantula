class RemoveDefectFieldFromStepExecutions < ActiveRecord::Migration
  
  def self.up
    # do some data migration here for defect texts?
    remove_column :step_executions, :defect
  end
  
  def self.down
    add_column :step_executions, :defect, :text
  end
  
end
