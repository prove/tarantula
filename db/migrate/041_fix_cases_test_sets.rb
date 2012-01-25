class FixCasesTestSets < ActiveRecord::Migration
  def self.up
    cases_test_sets = CasesTestSets.find(:all, :order => 'test_set_version DESC')
    cases_test_sets.each{|c|
      cases_test_sets.delete(c)
      cases_test_sets.each{|t|
        if ((c.case_id == t.case_id) && (c.test_set_id == t.test_set_id))
          t.destroy
        end
      }
    }
  end

  def self.down
  end
end
