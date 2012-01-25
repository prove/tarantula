class AddDefectFieldToStepExecution < ActiveRecord::Migration
  def self.up
    add_column :step_executions, :defect, :text
  end

  def self.down
    remove_column :step_executions, :defect
  end
end
