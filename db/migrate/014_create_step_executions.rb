class CreateStepExecutions < ActiveRecord::Migration
  def self.up
    create_table :step_executions do |t|
      t.column :step_id, :integer
      t.column :result, :string, :limit => 10
      t.column :created_at, :timestamp
      t.column :created_by, :integer
    end
  end

  def self.down
    drop_table :step_executions
  end
end
