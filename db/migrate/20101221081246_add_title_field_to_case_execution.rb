# Adds title attribute to CaseExecution for speeding up loading of
# case execution indexes.
#
# This removes the need of accessing versioned test case for the
# massive number of test cases during single request.
class AddTitleFieldToCaseExecution < ActiveRecord::Migration
  def self.up
    add_column :case_executions, :title, :string
    CaseExecution.all.each do |ce|
      begin
        ce.update_attributes(:title => ce.versioned_test_case.title)
      rescue
        next
      end
    end
  end

  def self.down
    remove_column :case_executions, :title
  end
end
