=begin rdoc

Module for different measurements, statistics, stuff.

=end
module Measure
  # cases that have been run in percentage to total cases
  def self.tested_coverage(test_object_ids, case_ids, test_area=nil)
    tos = TestObject.active.find(test_object_ids, :select => 'id, date')
    to = tos.first
    cases = Case.find(:all, :conditions => ["id IN (:ids) AND date <= :to_date",
                      {:ids => case_ids, :to_date => to.try(:date)}],
                      :select => 'id, updated_at')
    
    results = Case.cumulative_results(cases, tos.map(&:id), test_area)
    results.select{|r| [Passed, Failed].include?(r)}.size.in_percentage_to(results.size)
  end
  
  # cases for which the last case execution has passed in percentage to total
  # set result_type for other than Passed coverage
  def self.raw_passed_coverage(test_object_ids, case_ids, test_area=nil, result_type=Passed)
    tos = TestObject.active.find(test_object_ids, :select => 'id, date')
    to = tos.first
    cases = Case.find(:all, :conditions => ["id IN (:ids) AND date <= :to_date",
                      {:ids => case_ids, :to_date => to.try(:date)}],
                      :select => 'id, updated_at')
    
    results = Case.cumulative_results(cases, tos.map(&:id), test_area)
    results.select{|r| r == result_type}.size.in_percentage_to(results.size)
  end
  
  # Requirement coverage, also called "Requirements passed"
  def self.requirement_coverage(reqs, test_object_ids, test_area=nil)
    total = reqs.size
    passed = 0
    reqs.each do |r|
      cases = test_area ? r.cases_on_test_area(test_area) : r.cases
      next if cases.size == 0 # not passed if no cases
      # each case's last results should be passed
      next if cases.map{|c| c.last_results(test_object_ids, test_area).uniq == [Passed]}.include?(false)
      passed += 1
    end
    passed.in_percentage_to(total)
  end
  
  # Percentage of requirements completely tested in given test object; 
  # requirement is completely tested, if all related cases were run and 
  # result was either PASSED or FAILED.
  # If a case hasn't been run in given test object, result is fetched
  # from earlier test object, if any.
  def self.requirement_testing_coverage(reqs, to_ids, test_area=nil)
    total = reqs.size
    passed = 0
    reqs.each do |r|
      cases = test_area ? r.cases_on_test_area(test_area) : r.cases
      next if cases.size == 0 # not passed if no cases
      
      last_results = cases.map{|c| c.last_results(to_ids, test_area)}.flatten
      
      # no results, not passed
      next if last_results.empty?
      
      # each case's last results should be passed or failed
      next if ([Passed, Failed] | last_results).size > 2
      passed += 1
    end
    passed.in_percentage_to(total)
  end
  
end