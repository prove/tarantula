class AddProjectIdToExecution < ActiveRecord::Migration
  def self.up
    add_column :executions, :project_id, :integer
    
    # --- Data migration ---
    ActiveRecord::Base.connection.execute(
      'UPDATE executions, test_sets SET executions.project_id=test_sets.project_id '+
      'WHERE executions.test_set_id=test_sets.id')
  end

  def self.down
    remove_column :executions, :project_id
    # model validations fail here, no data migration
  end
end
