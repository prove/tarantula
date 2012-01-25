class AddResultToExecution < ActiveRecord::Migration
  def self.up
    add_column :executions, :result, :string, :default => 'NOT_RUN'
  end

  def self.down
    remove_column :executions, :result
  end
end
