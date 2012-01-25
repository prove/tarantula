class RemoveIdFromCasesTestSets < ActiveRecord::Migration
  
  def self.up
    remove_column :cases_test_sets, :id
    rename_column :cases_test_sets, :test_case_version, :case_version
    
    # --- DATA ---
    # add all cases from cases_test_sets to test set's current version
    
    TestSet.find(:all).each do |ts|
      data = select_all "SELECT cases_test_sets.case_id, cases.version, "+
        "cases_test_sets.position FROM cases JOIN cases_test_sets ON "+
        "cases.id = cases_test_sets.case_id "+
        "WHERE cases_test_sets.test_set_id = #{ts.id}"
      
      ts.updated_by = nil
      ts.save! # make a new version
      
      data.each do |d|
        execute "INSERT INTO cases_test_sets (test_set_id, test_set_version, "+
          "case_id, case_version, position) VALUES(#{ts.id}, #{ts.version}, "+
          "#{d['case_id']}, #{d['version']}, #{d['position']})"
      end
      
      execute "DELETE FROM cases_test_sets WHERE test_set_id=#{ts.id} "+
        "AND test_set_version < #{ts.version}"
    end
  end

  def self.down
    add_column :cases_test_sets, :id, :integer
    rename_column :cases_test_sets, :case_version, :test_case_version
  end
end
