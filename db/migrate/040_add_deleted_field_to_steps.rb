class AddDeletedFieldToSteps < ActiveRecord::Migration
  def self.up
    add_column :steps, :deleted, :boolean, {:default => false}
    add_column :step_versions, :deleted, :boolean, {:default => false}
  end

  def self.down
    remove_column :steps, :deleted
    remove_column :steps, :deleted
  end
end
