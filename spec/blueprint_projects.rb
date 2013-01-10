# -*- coding: utf-8 -*-

# require blueprint first

class Project < ActiveRecord::Base


  def self.make_simple
    simple = Project.make!(:name => 'Simple')
    testman = (User.find_by_login('Testman') || User.make!(:login => 'Testman'))
    ProjectAssignment.create!(:user => testman, :project => simple, :group => 'TEST_ENGINEER')

    ts = TestSet.make_with_cases({:project => simple, :name => 'set', :cases => 10},
                                 {:date => 1.month.ago.to_date, :creator => testman,
                                  :updater => testman})

    to1 = TestObject.make!(:name => 'TO1', :project => simple,
                          :date => 1.week.ago.to_date)
    to2 = TestObject.make!(:name => 'TO2', :project => simple,
                          :date => 1.day.ago.to_date)


    e1 = Execution.make!(:name => 'Exec1',
                        :test_object => to1,
                        :project => simple)

    [NotRun, Skipped, NotImplemented, Passed, Passed,
     Passed, Passed,  Passed, Failed, Passed].each_with_index do |res, i|
      atts = {:creator => testman,
              :assignee => testman,
              :test_case => simple.cases[i],
              :result => res,
              :position => i+1,
              :execution => e1}
      atts.merge!({:executor => testman, :duration => (rand(5)+1)*60}) if res != NotRun
      e1.case_executions << CaseExecution.make_with_result(atts)
    end

    e2 = Execution.make!(:name => 'Exec2',
                        :test_object => to2,
                        :project => simple)

    [NotRun, Passed, Passed, Passed, Passed,
     NotRun, Passed, Passed, Passed, Passed].each_with_index do |res, i|
      atts = {:creator => testman,
              :assignee => testman,
              :test_case => simple.cases[i],
              :result => res,
              :position => i+1,
              :execution => e2}
      atts.merge!({:executor => testman, :duration => (rand(5)+1)*60}) if res != NotRun
      e2.case_executions << CaseExecution.make_with_result(atts)
    end

    simple
  end

  def self.make_normal
    normal = Project.make!(:name => 'Normal')
    testman = (User.find_by_login('Testman') || User.make!(:login => 'Testman'))
    testman2 = (User.find_by_login('Testman2') || User.make!(:login => 'Testman2'))
    ProjectAssignment.create!(:user => testman, :project => normal, :group => 'TEST_ENGINEER')
    ProjectAssignment.create!(:user => testman2, :project => normal, :group => 'TEST_ENGINEER')

    ta = TestArea.make!(:name => 'TA1', :project => normal)
    ta2 = TestArea.make!(:name => 'TA2', :project => normal)

    ts = TestSet.make_with_cases({:project => normal, :name => 'set1', :cases => 10,
                                  :test_areas => [ta]},
                                 {:date => 1.month.ago.to_date, :creator => testman,
                                  :updater => testman, :test_areas => [ta]})

    ts.cases.each do |c|
      r = Requirement.make!(:project => normal,
                           :cases => [c],
                           :test_areas => [ta],
                           :date => 1.month.ago.to_date,
                           :creator => testman)
      r.cases << c
    end

    ts2 = TestSet.make_with_cases({:project => normal, :name => 'set2', :cases => 10,
                                   :test_areas => [ta2]},
                                  {:date => 1.month.ago.to_date, :creator => testman,
                                   :updater => testman, :test_areas => [ta2]})
    ts2.cases.each do |c|
      r = Requirement.make!(:project => normal,
                           :test_areas => [ta2],
                           :date => 1.month.ago.to_date,
                           :creator => testman)
      r.cases << c
    end


    to1 = TestObject.make!(:name => 'TO1', :project => normal,
                          :date => 2.week.ago.to_date, :test_areas => [ta,ta2])
    to2 = TestObject.make!(:name => 'TO2', :project => normal,
                          :date => 1.week.ago.to_date, :test_areas => [ta,ta2])
    to3 = TestObject.make!(:name => 'TO3', :project => normal,
                          :date => 1.day.ago.to_date, :test_areas => [ta,ta2])

    result_matrix = {to1 => {ta => %w(PASSED PASSED FAILED NOT_IMPL NOT_IMPL SKIPPED NOT_RUN NOT_RUN NOT_RUN NOT_RUN),
                             ta2 => %w(NOT_IMPL FAILED PASSED PASSED NOT_RUN SKIPPED NOT_RUN FAILED NOT_IMPL PASSED)},
                     to2 => {ta => %w(PASSED PASSED FAILED NOT_IMPL NOT_IMPL PASSED PASSED FAILED NOT_RUN NOT_RUN),
                             ta2 => %w(NOT_IMPL SKIPPED PASSED PASSED NOT_RUN PASSED PASSED FAILED SKIPPED PASSED)},
                     to3 => {ta => %w(FAILED PASSED PASSED PASSED FAILED PASSED PASSED PASSED PASSED SKIPPED),
                             ta2 => %w(PASSED PASSED FAILED PASSED PASSED PASSED PASSED SKIPPED PASSED PASSED)}}

    result_matrix.each do |to, results_per_area|
      results_per_area.each do |area, results|
        cases = area.cases
        user = (area == ta ? testman : testman2)

        e = Execution.make!(:name => "#{area.name} #{to.name} execution",
                           :test_object => to,
                           :project => normal,
                           :test_areas => [area])

        results.each_with_index do |res, i|
          atts = { :assignee => user,
                   :creator => testman,
                   :test_case => cases[i],
                   :result => ResultType.send(res),
                   :position => i+1,
                   :execution => e }
          atts.merge!({:executor => user, :duration => (rand(5)+1)*60}) if res != 'NOT_RUN'
          CaseExecution.make_with_result(atts)
        end
      end
    end
  end

  # 100 cases, not all cases on all test objects
  # 50 reqs on area [All], some have cases from both areas
  # 5 test objects
  # 2 test areas
  # 5 users (test designer)
  # some executions w/ many users assigned
  def self.make_advanced
    advanced = Project.make!(:name => 'Advanced')
    users = []

    5.times do |i|
      name = (i == 0 ? 'Testman' : "Testman#{i+1}")
      u = User.find_by_login(name) || User.make!(:login => name)
      users << u
      ProjectAssignment.create!(:user => u, :project => advanced,
                                :group => 'TEST_DESIGNER')
    end

    ta = TestArea.make!(:name => 'TA1', :project => advanced)
    ta2 = TestArea.make!(:name => 'TA2', :project => advanced)

    tobs = (1..5).map {|i| TestObject.make!(:name => "TO#{i}",
                                           :project => advanced,
                                           :date => (5-i).months.ago.to_date,
                                           :test_areas => [ta,ta2])}

    # new cases in 60/20/20/0/0 date-groups (to1,to2,to3,to4,to5)
    case_grp1 = (1..60).map{|i| c = Case.make_with_steps(:project => advanced,
                                                         :date => 4.months.ago.to_date,
                                                         :creator => users[0],
                                                         :test_areas => (i % 2 == 0 ? [ta] : [ta2]),
                                                         :updater => users[0])
                                c.tag_with('group1'); c}
    case_grp2 = (1..20).map{|i| c = Case.make_with_steps(:project => advanced,
                                                         :date => 3.months.ago.to_date,
                                                         :creator => users[1],
                                                         :test_areas => (i % 2 == 0 ? [ta] : [ta2]),
                                                         :updater => users[1])
                                c.tag_with('group2'); c}
    case_grp3 = (1..20).map{|i| c = Case.make_with_steps(:project => advanced,
                                                         :date => 2.months.ago.to_date,
                                                         :creator => users[2],
                                                         :test_areas => (i % 2 == 0 ? [ta] : [ta2]),
                                                         :updater => users[2])
                                c.tag_with('group3'); c}

    # new requirements in 30/10/10/0/0 date-groups
    req_grp1 = (1..30).map do |i|
      r = Requirement.make!(:project => advanced,
                           :date => 4.months.ago.to_date,
                           :creator => users[0],
                           :test_areas => [ta,ta2])
      r.tag_with('group1')
      r.cases << case_grp1[i*2,2]
      r
    end

    req_grp2 = (1..10).map do |i|
      r = Requirement.make!(:project => advanced,
                           :date => 3.months.ago.to_date,
                           :creator => users[0],
                           :test_areas => [ta,ta2])
      r.tag_with('group2')
      r.cases << case_grp2[i*2,2]
      r
    end

    req_grp3 = (1..10).map do |i|
      r = Requirement.make!(:project => advanced,
                           :date => 2.months.ago.to_date,
                           :creator => users[0],
                           :test_areas => [ta,ta2])
      r.tag_with('group3')
      r.cases << case_grp3[i*2,2]
      r
    end

    case_grps = [case_grp1,
                 (case_grp1 + case_grp2),
                 (case_grp1 + case_grp2 + case_grp3)]

    tobs.each_with_index do |to, to_i|
      e = Execution.make!(:name => "#{ta.name} #{to.name} execution",
                         :test_object => to,
                         :project => advanced,
                         :test_areas => [ta])

      e2 = Execution.make!(:name => "#{ta2.name} #{to.name} execution",
                         :test_object => to,
                         :project => advanced,
                         :test_areas => [ta2])

      g = (case_grps[to_i] || case_grps.last)
      g.each_with_index do |c, i|
        u = users.sample
        atts = { :assignee => u,
                 :creator => users[0],
                 :test_case => c,
                 :position => (i / 2) + 1,
                 :execution => (i % 2 == 1 ? e : e2),
                 :result => ResultType.all.sample }

        atts.merge!({:executor => u, :duration => (rand(5)+1)*60}) if atts[:result] != NotRun
        CaseExecution.make_with_result(atts)
      end
    end
  end

end
