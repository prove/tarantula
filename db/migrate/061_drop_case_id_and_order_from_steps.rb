class DropCaseIdAndOrderFromSteps < ActiveRecord::Migration
  
  # This information is available from cases_steps table.
  
  def self.up
    remove_column :steps, :case_id
    remove_column :steps, :order
  end

  def self.down
    add_column :steps, :case_id, :integer
    add_column :steps, :order, :integer
  end  
  
end
