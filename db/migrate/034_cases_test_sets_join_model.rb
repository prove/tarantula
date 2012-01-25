class CasesTestSetsJoinModel < ActiveRecord::Migration
  class TmpModel < ActiveRecord::Base
      set_table_name :cases_test_sets_tmpbackup
  end
  # 1. copy cases_test_sets to tmp table
  # 2. create new cases_test_sets for join model
  # 3. import data from tmp table
  def self.up
    rename_table :cases_test_sets, :cases_test_sets_tmpbackup
    create_table :cases_test_sets do |t|
      t.column :case_id, :integer, {:null => false}
      t.column :test_set_id, :integer, {:null => false}
      t.column :order, :integer, {:null => false, :default => 0}
    end

    TmpModel.find(:all).each{|tmp|
      CasesTestSets.create(:case_id => tmp.case_id, :test_set_id => tmp.test_set_id)
    }
    drop_table :cases_test_sets_tmpbackup
  end

  def self.down
    rename_table :cases_test_sets, :cases_test_sets_tmpbackup

    create_table :cases_test_sets, :id => false do |t|
      t.column :case_id, :integer
      t.column :test_set_id, :integer
    end
    add_index :cases_test_sets, [:test_set_id, :case_id]
    add_index :cases_test_sets, :case_id

  end
end
