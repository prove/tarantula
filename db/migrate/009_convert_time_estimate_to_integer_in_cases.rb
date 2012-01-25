class ConvertTimeEstimateToIntegerInCases < ActiveRecord::Migration
  def self.up
    remove_column :cases, :time_estimate
    add_column :cases, :time_estimate, :integer
  end

  def self.down
    remove_column :cases, :time_estimate
    add_column :cases, :time_estimate, :time
  end
end
