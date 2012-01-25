class AddExternalIdToCasesAndTestSets < ActiveRecord::Migration
  def self.up
    transaction do
      add_column :cases, :external_id, :string
      add_column :case_versions, :external_id, :string
    
      add_column :test_sets, :external_id, :string
      add_column :test_set_versions, :external_id, :string
    end
  end

  def self.down
    transaction do
      remove_column :cases, :external_id
      remove_column :case_versions, :external_id
    
      remove_column :test_sets, :external_id
      remove_column :test_set_versions, :external_id
    end  
  end
end
