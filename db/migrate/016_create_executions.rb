# Execution has one test set, and can be assigned to multiple testers
# Execution is complete, when all cases has been executed once, by
# any user.
class CreateExecutions < ActiveRecord::Migration
  def self.up
    create_table :executions do |t|
      t.column :name, :string
      t.column :test_set_id, :integer
      t.column :created_at, :timestamp
      t.column :created_by, :integer
    end
  end

  def self.down
    drop_table :executions
  end
end
