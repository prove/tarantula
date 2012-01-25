class AddCommentFieldToStepExecution < ActiveRecord::Migration
  def self.up
    add_column :step_executions, :comment, :text
  end

  def self.down
    remove_column :step_executions, :comment
  end
end
