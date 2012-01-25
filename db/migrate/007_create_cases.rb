class CreateCases < ActiveRecord::Migration
  def self.up
    create_table :cases do |t|
      t.column :title, :string
      # Id of the user who created case
      t.column :created_by, :integer
      t.column :created_at, :timestamp
      # Id of the user who modified case
      t.column :updated_by, :integer
      t.column :updated_at, :timestamp
      # Estimate of the execute time
      t.column :time_estimate, :time
      t.column :objective, :text
      t.column :test_data, :text
      t.column :preconditions_and_assumptions, :text
    end
  end

  def self.down
    drop_table :cases
  end
end
