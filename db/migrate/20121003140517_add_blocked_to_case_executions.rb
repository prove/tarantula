class AddBlockedToCaseExecutions < ActiveRecord::Migration
  def change
    add_column :case_executions, :blocked, :boolean, :default => 0
  end
end
