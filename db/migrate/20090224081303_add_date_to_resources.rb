class AddDateToResources < ActiveRecord::Migration
  
  def self.up
    rename_column :test_objects, :release_date, :date
    add_column :requirements, :date, :date
    add_column :executions, :date, :date
    
    # these are versioned
    add_column :cases, :date, :date
    add_column :case_versions, :date, :date
    
    add_column :test_sets, :date, :date
    add_column :test_set_versions, :date, :date
    
    ### Data migration
    [TestObject, Requirement, Execution, Case, TestSet].each do |klass|
      klass.all.each do |e|
        ActiveRecord::Base.connection.execute "update #{klass.to_s.tableize} "+
          "set `date`=created_at where `date` IS NULL"
      end
    end
  end

  def self.down
    rename_column :test_objects, :date, :release_date
    remove_column :requirements, :date
    remove_column :executions, :date
    
    # these are versioned
    remove_column :cases, :date
    remove_column :case_versions, :date
    
    remove_column :test_sets, :date
    remove_column :test_set_versions, :date
  end
end
