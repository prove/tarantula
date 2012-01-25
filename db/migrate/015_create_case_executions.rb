class CreateCaseExecutions < ActiveRecord::Migration
  def self.up
    create_table :case_executions do |t|
      t.column :case_id, :integer
      t.column :result, :string
      t.column :created_at, :timestamp
      t.column :created_by, :integer
    end
  end

  def self.down
    drop_table :case_executions
  end
end
