class CreateCasesSteps < ActiveRecord::Migration
  def self.up
    create_table :cases_steps, :id => false do |t|
      t.column :case_id, :integer
      t.column :case_version, :integer
      t.column :position, :integer
      t.column :step_id, :integer
      t.column :step_version, :integer
    end
    add_index :cases_steps, [:case_id] 
  end

  def self.down
    remove_index :cases_steps, [:case_id]
    drop_table :cases_steps
  end
end
