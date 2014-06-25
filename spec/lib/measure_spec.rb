require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Measure do
  describe ".tested_coverage" do

    it "should handle the basic case" do
      p = Project.make_with_cases(:cases => 5)
      e = Execution.make!(:project => p)
      CaseExecution.make_with_result(:test_case => p.cases.first,
                                     :execution => e,
                                     :result => Failed)

      Measure::tested_coverage([e.test_object_id], p.case_ids).should == 20
    end

    it "should not count in results in other test objects" do
      p = Project.make_with_cases(:cases => 5)
      e = Execution.make!(:project => p)
      CaseExecution.make_with_result(:test_case => p.cases.first,
                                     :execution => e,
                                     :result => Failed)

      Measure::tested_coverage([], p.case_ids).should == 0
    end

    it "should not count in results in other test areas" do
      p = Project.make_with_cases(:cases => 5)
      ta = p.test_areas.create!(:name => 'ta')
      p.cases.each{|c| c.test_areas << ta}

      e = Execution.make!(:project => p)
      e.test_areas << ta
      e2 = Execution.make!(:project => p)

      ce1 = CaseExecution.make_with_result(:test_case => p.cases[0],
                                           :execution => e,
                                           :result => Failed)

      ce2 = CaseExecution.make_with_result(:test_case => p.cases[1],
                                           :execution => e,
                                           :result => Passed)

      ce3 = CaseExecution.make_with_result(:test_case => p.cases[2],
                                           :execution => e2,
                                           :result => Failed)

      Measure::tested_coverage([e.test_object_id], p.case_ids, ta).should == 40
    end

    it "should not count in case execs which cases are not in the test area" do
      p = Project.make_with_cases(:cases => 5)
      ta = p.test_areas.create!(:name => 'ta')
      p.cases[1,4].each{|c| c.test_areas << ta}

      e = Execution.make!(:project => p)
      e.test_areas << ta

      ce1 = CaseExecution.make_with_result(:test_case => p.cases[0],
                                           :execution => e,
                                           :result => Failed)

      ce2 = CaseExecution.make_with_result(:test_case => p.cases[1],
                                           :execution => e,
                                           :result => Passed)

      Measure::tested_coverage([e.test_object_id], p.case_ids, ta).should == 25
    end

  end

  describe ".raw_passed_coverage" do
    # case executions which have passed in latest execution (%)
    it "should handle the basic case" do
      p = Project.make_with_cases(:cases => 2)
      e = Execution.make!(:project => p)
      # first round: both pass
      CaseExecution.make_with_result(:test_case => p.cases[0],
                                     :execution => e,
                                     :executed_at => 2.hours.ago,
                                     :result => Passed)
      CaseExecution.make_with_result(:test_case => p.cases[1],
                                     :execution => e,
                                     :executed_at => 2.hours.ago,
                                     :result => Passed)
      # later round: both fail
      e2 = Execution.make!(:project => p, :test_object => e.test_object)
      CaseExecution.make_with_result(:test_case => p.cases[0],
                                     :execution => e,
                                     :executed_at => 1.hours.ago,
                                     :result => Failed)
      CaseExecution.make_with_result(:test_case => p.cases[1],
                                     :execution => e,
                                     :executed_at => 1.hours.ago,
                                     :result => Failed)

      Measure::raw_passed_coverage([e.test_object_id], p.case_ids).should == 0
    end

    it "should handle the basic case (2)" do
      p = Project.make_with_cases(:cases => 3) # three cases!
      e = Execution.make!(:project => p)
      # first round: both pass
      CaseExecution.make_with_result(:test_case => p.cases[0],
                                     :execution => e,
                                     :executed_at => 2.hours.ago,
                                     :result => Failed)
      CaseExecution.make_with_result(:test_case => p.cases[1],
                                     :execution => e,
                                     :executed_at => 2.hours.ago,
                                     :result => Failed)
      # later round: both fail
      e2 = Execution.make!(:project => p, :test_object => e.test_object)
      CaseExecution.make_with_result(:test_case => p.cases[0],
                                     :execution => e,
                                     :executed_at => 1.hours.ago,
                                     :result => Passed)
      CaseExecution.make_with_result(:test_case => p.cases[1],
                                     :execution => e,
                                     :executed_at => 1.hours.ago,
                                     :result => Failed)

      Measure::raw_passed_coverage([e.test_object_id], p.case_ids).should == 33
    end

  end

  describe ".requirement_coverage" do

    it "should return 100 if only passed reqs with cases" do
      p = Project.make!
      c = Case.make!(:project => p)
      req = Requirement.make!(:project => p)
      req.cases << c
      e = Execution.make!(:project => p)
      e.case_executions << CaseExecution.make_with_result(:test_case => c,
                                                          :execution => e,
                                                          :position => 1,
                                                          :result => Passed)
      Measure::requirement_coverage([req], [e.test_object.id]).should == 100
    end

    it "should return 0 if requirement has no cases" do
      p = Project.make!
      c = Case.make!(:project => p)
      req = Requirement.make!(:project => p)
      # req.cases << c
      e = Execution.make!(:project => p)
      e.case_executions << CaseExecution.make_with_result(:test_case => c,
                                                          :execution => e,
                                                          :position => 1,
                                                          :result => Passed)
      Measure::requirement_coverage([req], [e.test_object.id]).should == 0
    end

    it "should return 50 if one passed and one failed req" do
      p = Project.make!
      c = Case.make!(:project => p)
      c2 = Case.make!(:project => p)
      req = Requirement.make!(:project => p)
      req.cases << c
      req2 = Requirement.make!(:project => p)
      req2.cases << c2

      e = Execution.make!(:project => p)
      e.case_executions << CaseExecution.make_with_result(:test_case => c,
                                                          :execution => e,
                                                          :position => 1,
                                                          :result => Passed)
      e.case_executions << CaseExecution.make_with_result(:test_case => c2,
                                                          :execution => e,
                                                          :position => 2,
                                                          :result => Skipped)

      Measure::requirement_coverage([req, req2], [e.test_object.id]).should == 50
    end

    it "should function with a 5-5-5 scenario (reqs-cases-testobjects)" do
      p = Project.make!
      cases = []
      reqs = []

      to1 = TestObject.make!(:project => p, :date => 5.weeks.ago)
      to2 = TestObject.make!(:project => p, :date => 4.weeks.ago)
      to3 = TestObject.make!(:project => p, :date => 3.weeks.ago)
      to4 = TestObject.make!(:project => p, :date => 2.weeks.ago)
      to5 = TestObject.make!(:project => p, :date => 1.week.ago)

      4.times do
        c = Case.make_with_steps(:project => p, :date => 1.month.ago)
        cases << c
        req = Requirement.make!(:project => p, :cases => [c], :date => 1.month.ago)
        req.cases << c
        reqs << req
      end

      e1 = Execution.make!(:test_object => to1, :project => p)
      [NotRun, NotRun, Passed, NotImplemented].each_with_index do |res, i|
        CaseExecution.make_with_result(:execution => e1,
                                       :test_case => cases[i],
                                       :position => i+1,
                                       :result => res)
      end
      Measure.requirement_coverage(reqs, [to1.id]).should == 25

      e2 = Execution.make!(:test_object => to2, :project => p)
      [Failed, Passed, Skipped, NotImplemented].each_with_index do |res, i|
        CaseExecution.make_with_result(:execution => e2,
                                       :test_case => cases[i],
                                       :position => i+1,
                                       :result => res)
      end
      Measure.requirement_coverage(reqs, [to2.id, to1.id]).should == 50

      e3 = Execution.make!(:test_object => to3, :project => p)
      [Failed, Skipped, Skipped, Skipped].each_with_index do |res, i|
        CaseExecution.make_with_result(:execution => e3,
                                       :test_case => cases[i],
                                       :position => i+1,
                                       :result => res)
      end
      Measure.requirement_coverage(reqs, [to3.id, to2.id, to1.id]).should == 50

      e4 = Execution.make!(:test_object => to4, :project => p)
      [Passed, Passed, NotRun, Passed].each_with_index do |res, i|
        CaseExecution.make_with_result(:execution => e4,
                                       :test_case => cases[i],
                                       :position => i+1,
                                       :result => res)
      end
      Measure.requirement_coverage(reqs, [to4.id, to3.id, to2.id, to1.id]).should == 100

      e5 = Execution.make!(:test_object => to5, :project => p)
      [NotRun, NotRun, NotRun, NotRun].each_with_index do |res, i|
        CaseExecution.make_with_result(:execution => e5,
                                       :test_case => cases[i],
                                       :position => i+1,
                                       :result => res)
      end
      Measure.requirement_coverage(reqs, [to5.id, to4.id, to3.id, to2.id, to1.id]).should == 100

      # Ensure that other test runs won't interfere when calculating
      # coverage for single test object only
      Measure.requirement_coverage(reqs, [to1.id]).should == 25
      Measure.requirement_coverage(reqs, [to4.id]).should == 75
      Measure.requirement_coverage(reqs, [to5.id]).should == 0
    end

  end

end
