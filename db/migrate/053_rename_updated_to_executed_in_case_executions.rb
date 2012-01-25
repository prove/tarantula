class RenameUpdatedToExecutedInCaseExecutions < ActiveRecord::Migration
  def self.up
    # Need to track who executed what and when.
    # Updates should be tracked otherwise at whole execution level.
    rename_column :case_executions, :updated_by, :executed_by
    rename_column :case_executions, :updated_at, :executed_at  
  end

  def self.down
    rename_column :case_executions, :executed_by, :updated_by
    rename_column :case_executions, :executed_at, :updated_at  
  end
end
