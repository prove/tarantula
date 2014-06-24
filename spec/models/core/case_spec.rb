require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require "#{Rails.root}/lib/attsets/spec/shared/attachment_host_spec"

describe Case do

  before(:all) do
    Rake.application.rake_require "db_create_views", [File.join(Rails.root, 'lib', 'tasks')]
  end

  # for shared behaviours
  def get_instance(atts={})
    c = Case.make!(atts)
    def c.new_versioned_child
      Step.new(:action => 'a', :result => 'r', :position => rand(100)+1)
    end
    def c.versioned_assoc_name; 'steps'; end
    c
  end

  it_behaves_like "attachment host"
  it_behaves_like "taggable"
  it_behaves_like "versioned"
  it_behaves_like "auditable"
  it_behaves_like "externally_identifiable"
  it_behaves_like "date stamped"
  it_behaves_like "prioritized"

  describe "#avg_duration" do
    it "should call Case.total_avg_duration" do
      c = Case.make!
      flexmock(Case).should_receive(:total_avg_duration).with(
        [c.id], true)
      c.avg_duration(true)
    end
  end

  it "#median_duration should return median duration of case_executions" do
    c = Case.make!
    e = Execution.make!
    c.case_executions << CaseExecution.make!(:duration => 3, :execution => e)
    c.case_executions << CaseExecution.make!(:duration => 5, :execution => e)
    c.case_executions << CaseExecution.make!(:duration => 8, :execution => e)
    c.case_executions << CaseExecution.make!(:duration => 11,:execution => e)
    c.median_duration.should == 8
  end

  it "#passed_count should return case_executions passed" do
    c = Case.make!
    e = Execution.make!
    c.case_executions << CaseExecution.make_with_result(:result => Passed,
                                                        :execution => e)
    c.case_executions << CaseExecution.make_with_result(:result => Skipped,
                                                        :execution => e)
    c.case_executions << CaseExecution.make_with_result(:result => Failed,
                                                        :execution => e)
    c.passed_count.should == 1
  end

  it "#failed_count should return case_executions failed" do
    c = Case.make!
    e = Execution.make!
    c.case_executions << CaseExecution.make_with_result(:result => Passed,
                                                        :execution => e)
    c.case_executions << CaseExecution.make_with_result(:result => Failed,
                                                        :execution => e)
    c.case_executions << CaseExecution.make_with_result(:result => Failed,
                                                        :execution => e)
    c.failed_count.should == 2
  end

  it "#skipped_count should return case_executions skipped" do
    c = Case.make!
    e = Execution.make!
    c.case_executions << CaseExecution.make_with_result(:result => Passed,
                                                        :execution => e)
    c.case_executions << CaseExecution.make_with_result(:result => Failed,
                                                        :execution => e)
    c.case_executions << CaseExecution.make_with_result(:result => Passed,
                                                        :execution => e)
    c.skipped_count.should == 0
  end

  it "#to_tree should return necessary data" do
    c = Case.make
    data = c.to_tree
    data.should have_key(:text)
    data.should have_key(:leaf)
    data.should have_key(:dbid)
    data.should have_key(:cls)
    data.should have_key(:tags)
    data.should have_key(:deleted)
    data.should have_key(:archived)
    data.should have_key(:version)
    data.should have_key(:tasks)
    data.keys.size.should == 9
  end

  it "#to_data should return necessary data" do
    u = User.make!
    c = Case.make!(:updater => u, :creator => u)
    data = c.to_data
    data.should have_key(:id)
    data.should have_key(:date)
    data.should have_key(:title)
    data.should have_key(:time_estimate)
    data.should have_key(:created_by)
    data.should have_key(:created_at)
    data.should have_key(:updated_by)
    data.should have_key(:updated_at)
    data.should have_key(:objective)
    data.should have_key(:test_data)
    data.should have_key(:preconditions_and_assumptions)
    data.should have_key(:version)
    data.should have_key(:deleted)
    data.should have_key(:archived)
    data.should have_key(:average_duration)
    data.should have_key(:project_id)
    data.should have_key(:tasks)
    data.should have_key(:test_area_ids)
    data.should have_key(:priority)
    data.keys.size.should == 19
  end

  it "#to_data should return necessary data [brief mode]" do
    c = Case.make!(:time_estimate => 5)
    data = c.to_data(:brief)
    data.should have_key(:position)
    data.should have_key(:id)
    data.should have_key(:date)
    data.should have_key(:title)
    data.should have_key(:time_estimate)
    data.should have_key(:version)
    data.should have_key(:test_area_ids)
    data.should have_key(:priority)
    data.should have_key(:objective)
    data.should have_key(:test_data)
    data.should have_key(:preconditions_and_assumptions)
    data.keys.size.should == 11
  end

  it "should copy attachments from original if created by copying" do
    c = Case.make!
    att = Attachment.make!
    c.attach(att)

    c2 = Case.make!(:original_id => c.id)
    c2.attachments.size.should == 1
    c2.attachments.should include(att)
  end

  describe "#copy_to" do
    it "should set needed attributes to the new copy" do
      orig_case = Case.make!(:position => 1)
      p = Project.make!
      u = User.make!
      ts = TestSet.make!
      ts.cases << orig_case

      orig_case.copy_to(p, u)
      p.cases.size.should == 1
      copied_case = p.cases.first
      copied_case.original_id.should == orig_case.id
      copied_case.created_by.should == u.id
      copied_case.updated_by.should == u.id
      copied_case.test_sets.should be_empty
      copied_case.change_comment.should == \
        "Copied from project #{orig_case.project.name} case #{orig_case.title}"
      copied_case.attributes.size.should == 19 # New attributes? Adjust?
    end

    it "should create equivalent steps for the copy" do
      u = User.make!
      p = Project.make!
      c = Case.make!
      c.steps << [
         Step.new(:action => 'a1', :result => 'r1', :position => 1),
         Step.new(:action => 'a2', :result => 'r2', :position => 2),
         Step.new(:action => 'a3', :result => 'r3', :position => 3)
         ]

      c.copy_to(p, u)
      copied = p.cases.first

      copied.steps.size.should == 3
      copied.steps[0].action.should == 'a1'
      copied.steps[1].action.should == 'a2'
      copied.steps[2].action.should == 'a3'
      copied.steps[0].result.should == 'r1'
      copied.steps[1].result.should == 'r2'
      copied.steps[2].result.should == 'r3'
      copied.steps[0].position.should == 1
      copied.steps[1].position.should == 2
      copied.steps[2].position.should == 3
    end

    it "should add (Copy) to copied case's title if copied to same project" do
      u = User.make!
      c = Case.make!

      copied = c.copy_to(c.project, u)
      copied.title.should == c.title + " (Copy)"
    end

    it "should tag the original case with name of the target project "+
       "when copied from library-project" do
      user = User.make!
      target_project = Project.make!
      library_project = Project.make_with_cases(:library => true, :cases => 1)
      orig_case = library_project.cases.first
      orig_case.tags.size.should == 0

      orig_case.copy_to(target_project,user)
      orig_case.tags.should == [Tag.find_by_name(target_project.name)]
    end

    it "should copy the tags of the original case" do
      u = User.make!
      c = Case.make!
      c.tag_with('blade, runner')
      copied = c.copy_to(c.project, u)
      copied.has_tags?([Tag.find_by_name('blade'),
                        Tag.find_by_name('runner')]).should == true
    end

    it "should copy to test area if test area id given" do
      u = User.make!
      c = Case.make!
      p_to = Project.make!
      ta_to = TestArea.make!(:project => p_to)
      copied = c.copy_to(p_to, u, [ta_to.id])
      ta_to.cases.should == [copied]
    end

    it "should not copy 'deleted' attribute" do
      u = User.make!
      c = Case.make!(:deleted => true)
      p_to = Project.make!
      copied = c.copy_to(p_to, u)
      copied.deleted.should == false
    end

    it "should not copy 'archived' attribute" do
      u = User.make!
      c = Case.make!(:archived => true)
      p_to = Project.make!
      copied = c.copy_to(p_to, u)
      copied.archived.should == false
    end

  end

  describe "#history" do
    it "should show three latest run case executions" do
      c = Case.make!
      e = Execution.make!
      ce1 = CaseExecution.make_with_result(:execution => e, :test_case => c,
                                           :result => Skipped)
      ce2 = CaseExecution.make_with_result(:execution => e, :test_case => c,
                                           :result => Failed)
      ce3 = CaseExecution.make_with_result(:execution => e, :test_case => c,
                                           :result => Skipped)
      ce4 = CaseExecution.make_with_result(:execution => e, :test_case => c,
                                           :result => Passed)
      ce5 = CaseExecution.make_with_result(:execution => e, :test_case => c,
                                           :result => NotRun)
      hist = c.history
      hist.size.should == 4
      hist[0][:result].should == Passed.ui
      hist[1][:result].should == Skipped.ui
      hist[2][:result].should == Failed.ui
      hist[3][:result].should == Skipped.ui
    end

    it "shouldn't show results of deleted executions" do
      p = Project.make!
      c = Case.make!(:project => p)
      e = Execution.make!(:project => p, :deleted => true)
      ce1 = CaseExecution.make_with_result(:execution => e, :test_case => c,
                                           :result => Skipped)
      ce2 = CaseExecution.make_with_result(:execution => e, :test_case => c,
                                           :result => Failed)
      e2 = Execution.make!(:project => p)
      ce1 = CaseExecution.make_with_result(:execution => e2, :test_case => c,
                                           :result => Passed)
      c.history.size.should == 1
      c.history[0][:result].should == Passed.ui
    end
  end

  describe ".create_with_steps!" do

    it "should create a case and its steps" do
      steps_assoc = flexmock('steps assoc')
      steps_assoc.should_receive(:<<).once
      m_case = flexmock('case', :steps => steps_assoc)
      m_case.should_receive(:tag_with).once.with('a_tag')

      flexmock(Case).should_receive(:create!).with({'key' => 'val'}).once.\
        and_return(m_case)
      flexmock(Step).should_receive(:new).once.with({'skey' => 'sval'})

      Case.create_with_steps!({'key' => 'val'}, [{'skey' => 'sval'}], 'a_tag')
    end

    it "should create a case execution after given case execution "+
       "if :execution_id and :case_execution_id provided" do
      e = Execution.make!
      ce1 = CaseExecution.make!(:execution => e, :position => 1)
      ce2 = CaseExecution.make!(:execution => e, :position => 2)
      ce3 = CaseExecution.make!(:execution => e, :position => 3)
      ce4 = CaseExecution.make!(:execution => e, :position => 4)
      c = Case.make!(:project => e.project)
      flexmock(Case).should_receive(:create!).once.and_return(c)

      Case.create_with_steps!({:case_execution_id => ce2.id,
                               :execution_id => e.id}, [], nil)
      e.reload
      e.case_executions[0].should == ce1
      e.case_executions[1].should == ce2
      e.case_executions[3].should == ce3
      e.case_executions[4].should == ce4
    end

    it "should create a case execution at position 1 if :execution_id provided" do
      e = Execution.make!
      ce1 = CaseExecution.make!(:execution => e, :position => 1)
      ce2 = CaseExecution.make!(:execution => e, :position => 2)
      ce3 = CaseExecution.make!(:execution => e, :position => 3)
      ce4 = CaseExecution.make!(:execution => e, :position => 4)
      c = Case.make!(:project => e.project)
      flexmock(Case).should_receive(:create!).once.and_return(c)

      Case.create_with_steps!({:execution_id => e.id}, [], nil)
      e.reload
      e.case_executions[1].should == ce1
      e.case_executions[2].should == ce2
      e.case_executions[3].should == ce3
      e.case_executions[4].should == ce4
    end

  end

  it "#update_with_steps should update case and its steps" do
    atts = {'key' => 'val'}
    steps = [{'id' => 1, 'skey' => 'sval'}]
    tags = "a_tag"
    a_step = flexmock('step')
    a_step.should_receive(:update_if_needed).once.with(steps.first)
    steps_assoc = flexmock('steps assoc', :detect => a_step)
    steps_assoc.should_receive(:<<).once.with(a_step)
    a_case = flexmock(Case.new, :steps => steps_assoc)
    a_case.should_receive(:update_attributes!).once.with(atts)
    a_case.should_receive(:tag_with).once.with(tags)

    a_case.update_with_steps!(atts, steps, tags)
  end

  it "#update_with_steps should update date properly" do
    c = Case.make(:date => 1.month.ago)
    c.update_with_steps!({:date => "2011-11-09T00:00:00"}, [])
    c.date.should == Date.parse("2011-11-09T00:00:00")
  end

  it "#destroying a case should destroy all its steps" do
    c = Case.make!(:steps => [Step.make!, Step.make!])
    id = c.id
    step_ids = c.steps.map(&:id)
    c.destroy
    Step.find(step_ids).should be_empty
  end

  describe ".total_avg_duration" do
    it "should show estimate if no executions" do
      c = Case.make!(:time_estimate => 5)

      Rake::Task['db:create_views'].execute(nil)
      Case.total_avg_duration([c.id]).should == 300
    end

    it "should show average duration if executions present" do
      c = Case.make!(:time_estimate => 5)
      CaseExecution.make_with_result(:test_case => c,
                                     :duration => 20,
                                     :result => Passed)

      Rake::Task['db:create_views'].execute(nil)
      Case.total_avg_duration([c.id]).should == 20
    end

    it "should show average duration if executions present, pt. 2" do
      c = Case.make!(:time_estimate => 5)
      CaseExecution.make_with_result(:test_case => c,
                                     :duration => 20,
                                     :result => Passed)
      CaseExecution.make_with_result(:test_case => c,
                                     :duration => 40,
                                     :result => Passed)
      CaseExecution.make_with_result(:test_case => c,
                                     :duration => 60,
                                     :result => Passed)

      Rake::Task['db:create_views'].execute(nil)
      Case.total_avg_duration([c.id]).should == 40
    end

    it "should combine avg. duration and estimate" do
      c1 = Case.make!(:time_estimate => 5)
      c2 = Case.make!(:time_estimate => 10)
      c3 = Case.make!(:time_estimate => 10)
      CaseExecution.make_with_result(:test_case => c2,
                                     :duration => 20,
                                     :result => Passed)
      CaseExecution.make_with_result(:test_case => c3,
                                     :duration => 20,
                                     :result => Passed)

      Rake::Task['db:create_views'].execute(nil)
      Case.total_avg_duration([c1.id, c2.id, c3.id]).should == 340
    end

    it "should count in a case as many times as it's id is given, avg" do
      c1 = Case.make!
      CaseExecution.make_with_result(:test_case => c1,
                                     :duration => 20,
                                     :result => Passed)

      Rake::Task['db:create_views'].execute(nil)
      Case.total_avg_duration([c1.id, c1.id]).should == 40
    end

    it "should count in a case as many times as it's id is given, estimates" do
      c1 = Case.make!(:time_estimate => 5)
      c2 = Case.make!(:time_estimate => 10)

      Rake::Task['db:create_views'].execute(nil)
      Case.total_avg_duration([c1.id, c1.id, c2.id, c2.id]).should == 1800
    end

    it "should count in a case as many times as it's id is given, estimates" do
      c1 = Case.make!(:time_estimate => 5)
      c2 = Case.make!(:time_estimate => 10)

      Rake::Task['db:create_views'].execute(nil)
      Case.total_avg_duration([c1.id, c1.id, c2.id, c2.id]).should == 1800
    end

    it "should count in a case as many times as it's id is given, avg+estimates" do
      c1 = Case.make!(:time_estimate => 5)
      c2 = Case.make!(:time_estimate => 10)
      CaseExecution.make_with_result(:test_case => c1,
                                     :duration => 100,
                                     :result => Passed)

      Rake::Task['db:create_views'].execute(nil)
      Case.total_avg_duration([c1.id, c2.id, c1.id, c2.id]).should == 1400
    end

  end

  describe "#last_passed" do
    it "should return the test object the case was last passed in" do
      p = Project.make!
      u = User.make!
      c = Case.make!(:project => p)
      to = TestObject.make!(:project => p)
      to2 = TestObject.make!(:project => p)
      e = Execution.make!(:test_object => to, :project => p)
      e2 = Execution.make!(:test_object => to2, :project => p)
      CaseExecution.create!(:test_case => c,
                            :position => 1,
                            :execution => e,
                            :executor => u,
                            :result => Passed,
                            :executed_at => 1.day.ago)
      CaseExecution.create!(:test_case => c,
                            :position => 1,
                            :execution => e2,
                            :executor => u,
                            :result => Passed,
                            :executed_at => 1.hour.ago)
      c.last_passed.should == to2
    end
  end

  describe "#last_tested" do
    it "should return the test object the case was last tested in" do
      p = Project.make!
      u = User.make!
      c = Case.make!(:project => p)
      to = TestObject.make!(:project => p)
      to2 = TestObject.make!(:project => p)
      e = Execution.make!(:test_object => to, :project => p)
      e2 = Execution.make!(:test_object => to2, :project => p)
      CaseExecution.create!(:test_case => c,
                            :position => 1,
                            :execution => e,
                            :executor => u,
                            :result => Passed,
                            :executed_at => 1.day.ago)
      CaseExecution.create!(:test_case => c,
                            :position => 1,
                            :execution => e2,
                            :executor => u,
                            :result => Passed,
                            :executed_at => 1.hour.ago)
      c.last_tested.should == to2
    end
  end

  describe "#last_result" do
    it "should return the last result of this case's executions" do
      p = Project.make!
      u = User.make!
      c = Case.make!(:project => p)
      to = TestObject.make!(:project => p)
      to2 = TestObject.make!(:project => p)
      e = Execution.make!(:test_object => to, :project => p)
      e2 = Execution.make!(:test_object => to2, :project => p)
      CaseExecution.create!(:test_case => c,
                            :position => 1,
                            :execution => e,
                            :executor => u,
                            :result => Passed,
                            :executed_at => 1.day.ago)
      CaseExecution.create!(:test_case => c,
                            :position => 1,
                            :execution => e2,
                            :executor => u,
                            :result => Skipped,
                            :executed_at => 1.hour.ago)
      c.last_result.should == Skipped
    end
  end

  describe "#last_results" do
    it "should return results of last test object" do
      to = TestObject.make!(:date => 2.months.ago)
      to2 = TestObject.make!(:date => 1.month.ago)
      c = Case.make!(:date => 3.months.ago)
      CaseExecution.make_with_result(
        :test_case => c, :execution => Execution.make!(:test_object => to),
        :result => Passed)
      CaseExecution.make_with_result(
        :test_case => c, :execution => Execution.make!(:test_object => to2),
        :result => Failed)
      c.last_results([to.id]).should == [Passed]
      c.last_results([to2.id]).should == [Failed]
    end

    it "should not include NOT_RUN or SKIPPED" do
      to = TestObject.make!(:date => 2.months.ago)
      to2 = TestObject.make!(:date => 1.month.ago)
      c = Case.make!(:date => 3.months.ago)
      CaseExecution.make_with_result(
        :test_case => c, :execution => Execution.make!(:test_object => to),
        :result => Passed)
      CaseExecution.make_with_result(
        :test_case => c, :execution => Execution.make!(:test_object => to2),
        :result => Skipped)
      ce = CaseExecution.make_with_result(
        :test_case => c, :execution => Execution.make!(:test_object => to2),
        :result => NotRun)
      c.last_results([to.id]).should == [Passed]
      c.last_results([to.id, to2.id]).should == [Passed]
    end

    it "should be updated when execution's test object changes" do
      p = Project.make!
      to = TestObject.make!(:date => 2.months.ago, :project => p)
      to2 = TestObject.make!(:date => 1.month.ago, :project => p)
      to3 = TestObject.make!(:date => Date.today, :project => p)

      c = Case.make!(:date => 3.months.ago, :project => p)
      sleep(1) # so the cache key will be changed

      # reference
      CaseExecution.make_with_result(
        :test_case => c, :execution => Execution.make!(:test_object => to2,
                                                       :project => p),
        :result => Passed)

      e = Execution.make!(:test_object => to3, :project => p)

      CaseExecution.make_with_result(:test_case => c, :execution => e,
        :result => Failed)

      c.last_results([to3.id, to2.id, to.id]).should == [Failed]

      e.update_attributes!(:test_object_id => to.id)

      Case.find(c.id).last_results([to3.id, to2.id, to.id]).should == [Passed]
    end

  end


  describe "#last_failed_exec" do
    it "should return the execution where this case last failed" do
      p = Project.make!
      u = User.make!
      c = Case.make!(:project => p)
      to = TestObject.make!(:project => p)
      to2 = TestObject.make!(:project => p)
      e = Execution.make!(:test_object => to, :project => p)
      e2 = Execution.make!(:test_object => to2, :project => p)
      CaseExecution.create!(:test_case => c,
                            :position => 1,
                            :execution => e,
                            :executor => u,
                            :result => Failed,
                            :executed_at => 1.day.ago)
      CaseExecution.create!(:test_case => c,
                            :position => 1,
                            :execution => e2,
                            :executor => u,
                            :result => Skipped,
                            :executed_at => 1.hour.ago)
      c.last_failed_exec.should == e
    end
  end

  describe "#cumulative_results" do

    it "should return empty result if no cases" do
      Case.cumulative_results([], []).should == []
    end

    it "should return nil if no executions for a case" do
      p = Project.make!
      c = Case.make!(:project => p)
      to = TestObject.make!(:project => p)
      Case.cumulative_results([c], [to.id]).should == [nil]
    end

    it "should return the last result (1 case, 1 test object)" do
      p = Project.make!
      c = Case.make!(:project => p)
      to = TestObject.make!(:project => p)
      e = Execution.make!(:project => p, :test_object => to)
      CaseExecution.make_with_result(:result => Failed,
                                     :test_case => c,
                                     :execution => e)
      Case.cumulative_results([c], [to.id]).should == [Failed]
    end

    it "should return the last result (1 case, 1 test object) [two runs]" do
      p = Project.make!
      c = Case.make!(:project => p)
      to = TestObject.make!(:project => p)
      e = Execution.make!(:project => p, :test_object => to)
      CaseExecution.make_with_result(:result => Failed,
                                     :test_case => c,
                                     :executed_at => 2.days.ago,
                                     :execution => e)
      CaseExecution.make_with_result(:result => Passed,
                                     :test_case => c,
                                     :executed_at => 1.day.ago,
                                     :execution => e)
      Case.cumulative_results([c], [to.id]).should == [Passed]
    end

    it "should exclude executions from other test areas (1 case, 1 test object)" do
      p = Project.make!
      ta1 = TestArea.make!(:project => p)
      ta2 = TestArea.make!(:project => p)
      c = Case.make!(:project => p, :test_areas => [ta1, ta2])
      to = TestObject.make!(:project => p, :test_areas => [ta2])
      e = Execution.make!(:project => p, :test_object => to, :test_areas => [ta2])
      CaseExecution.make_with_result(:result => Passed,
                                     :test_case => c,
                                     :executed_at => 1.day.ago,
                                     :execution => e)
      Case.cumulative_results([c], [to.id], ta1).should == [nil]
      # on the other hand:
      Case.cumulative_results([c], [to.id], ta2).should == [Passed]
    end

    it "should persist results from older test objects (2 cases, 2 test objects)" do
      p = Project.make!
      c1 = Case.make!(:project => p)
      c2 = Case.make!(:project => p)

      to1 = TestObject.make!(:project => p, :date => 1.week.ago.to_date)
      e1 = Execution.make!(:project => p, :test_object => to1)
      CaseExecution.make_with_result(:result => Failed,
                                     :test_case => c1,
                                     :execution => e1)

      to2 = TestObject.make!(:project => p, :date => Date.today)
      e2 = Execution.make!(:project => p, :test_object => to2)
      CaseExecution.make_with_result(:result => Passed,
                                     :test_case => c1,
                                     :execution => e2)
      CaseExecution.make_with_result(:result => Skipped,
                                     :test_case => c2,
                                     :execution => e2)

      # N.B. Skipped is not counted in
      Case.cumulative_results([c1,c2], [to2.id]).should == [Passed, nil]
    end

  end

  it "return step count with .step_count" do
    c1 = Case.make!
    c2 = Case.make!
    c3 = Case.make!
    c2.save
    c2.steps << Step.make!(:position => 9)
    Case.step_count([c1.id, c2.id, c3.id]).should == \
      (c1.steps.size + c2.steps.size + c3.steps.size)
  end

  describe "#toggle_deleted" do
    it "should set deleted and reset archived" do
      c = Case.make!(:deleted => false, :archived => true)
      c.version.should == 1
      c.toggle_deleted
      c.reload
      c.deleted.should == true
      c.archived.should == false
      c.version.should == 1
    end

    it "should unset deleted" do
      c = Case.make!(:deleted => true, :archived => false)
      c.version.should == 1
      c.toggle_deleted
      c.reload
      c.deleted.should == false
      c.archived.should == false
      c.version.should == 1
    end

    it "should clear links to test sets" do
      p = Project.make!
      c = Case.make!(:position => 2, :project => p)
      old_steps = c.steps.map{|s| [s.position, s.action, s.result]}
      c2 = Case.make!(:position => 3, :project => p)
      c0 = Case.make!(:position => 1, :project => p)
      ts = TestSet.make!(:project => p)
      ts.cases << c0
      ts.cases << c
      ts.cases << c2
      c.toggle_deleted

      c.steps.map{|s| [s.position, s.action, s.result]}.should == old_steps

      c.version.should == 2
      ts.reload
      ts.version.should == 2
      new_cases = ts.cases.reload
      new_cases.size.should == 2
      new_cases.first.position.should == 1
      new_cases.first.id.should == c0.id
      new_cases[1].position.should == 2
      new_cases[1].id.should == c2.id
    end

    it "should clear links to requirements" do
      p = Project.make!
      c = Case.make!(:position => 2, :archived => true, :project => p)
      step_count = c.steps.size
      c2 = Case.make!(:position => 3, :project => p)
      c0 = Case.make!(:position => 1, :project => p)
      req = Requirement.make!(:project => p)
      req.cases << c0
      req.cases << c
      req.cases << c2
      c.toggle_deleted

      c.requirements.should == []
      c.deleted.should == true
      c.archived.should == false
      c.steps.size.should == step_count

      c.version.should == 2
      req.reload
      req.version.should == 2
      new_cases = req.cases.reload
      new_cases.size.should == 2
      new_cases.first.id.should == c0.id
      new_cases[1].id.should == c2.id
    end

    it "should clear older version from set" do
      p = Project.make!
      c = Case.make!(:position => 1, :project => p, :title => 'deleting case')
      ts = TestSet.make!(:project => p)
      ts.cases << c
      c.save
      c.reload
      c.version.should == 2
      c.toggle_deleted

      c.reload.version.should == 3

      ts.reload.version.should == 2
      ts.cases.should be_empty
    end

    it "should not make new version of a test set if case not included in current version" do
      p = Project.make!
      c = Case.make!(:position => 1, :project => p, :title => 'deleting case')
      ts = TestSet.make!(:project => p)
      ts.cases << c
      ts.save!
      ts.cases << Case.make!(:position => 1, :project => p, :title => 'another case')
      ts.version.should == 2
      c.toggle_deleted

      ts.reload.version.should == 2
      ts.revert_to(1)
      ts.cases.should == [c]
    end

    it "should clear older version from requirement" do
      p = Project.make!
      c = Case.make!(:project => p, :title => 'deleting case')
      req = Requirement.make!(:project => p)
      req.cases << c
      c.save
      c.reload
      c.version.should == 2
      c.toggle_deleted

      c.reload.version.should == 3

      req.reload.version.should == 2
      req.cases.should be_empty
    end

    it "should not make new version of a requirement if case not included in current version" do
      p = Project.make!
      c = Case.make!(:position => 1, :project => p, :title => 'deleting case')
      req = Requirement.make!(:project => p)
      req.cases << c
      req.save!
      req.cases << Case.make!(:position => 1, :project => p, :title => 'another case')
      req.version.should == 2
      c.toggle_deleted

      req.reload.version.should == 2
      req.revert_to(1)
      req.cases.should == [c]
    end

  end

  describe ".copy_many_to" do
    it "should copy by case_ids" do
      copy_from = Project.make!(:name => 'copy from')
      copy_to = Project.make!(:name => 'copy to')

      c1 = Case.make!(:project => copy_from)
      c2 = Case.make!(:project => copy_from)

      Case.copy_many_to(copy_to.id,
        {:user => @user, :case_ids => "#{c1.id},#{c2.id}",
         :from_project => copy_from})

      copy_to.reload.cases.count.should == 2
    end

    it "should copy by case_ids to test area" do
      copy_from = Project.make!(:name => 'copy from')
      copy_to = Project.make!(:name => 'copy to')
      ta = TestArea.make!(:project => copy_to)

      c1 = Case.make!(:project => copy_from)
      c2 = Case.make!(:project => copy_from)

      Case.copy_many_to(copy_to.id,
        {:user => @user, :case_ids => "#{c1.id},#{c2.id}",
         :to_test_areas => ta.id.to_s, :from_project => copy_from})

      copy_to.reload.cases.count.should == 2
      ta.reload.cases.count.should == 2
    end

    it "should copy by case_ids on test area" do
      copy_from = Project.make!(:name => 'copy from')
      copy_to = Project.make!(:name => 'copy to')

      ta1 = TestArea.make!(:project => copy_from)

      c1 = Case.make!(:project => copy_from, :test_areas => [ta1])
      c2 = Case.make!(:project => copy_from)

      Case.copy_many_to(copy_to.id,
        {:user => @user, :case_ids => "#{c1.id},#{c2.id}",
         :from_test_area => ta1, :from_project => copy_from})

      copy_to.reload.cases.count.should == 1
    end


    it "should copy by tag_ids" do
      copy_from = Project.make!(:name => 'copy from')
      copy_to = Project.make!(:name => 'copy to')

      c1 = Case.make!(:project => copy_from)
      c2 = Case.make!(:project => copy_from)
      c3 = Case.make!(:project => copy_from)
      c4 = Case.make!(:project => copy_from)
      c5 = Case.make!

      c1.tag_with('outer')
      c2.tag_with('outer')
      c3.tag_with('outer,inner')
      c4.tag_with('outer,inner')

      tag_ids = "#{Tag.find_by_name('outer').id},#{Tag.find_by_name('inner').id}"

      Case.copy_many_to(copy_to.id, {:user => @user, :tag_ids => tag_ids,
                                     :from_project => copy_from})

      copy_to.reload.cases.count.should == 2
    end

    it "should copy by tag_ids on test area" do
      copy_from = Project.make!(:name => 'copy from')
      copy_to = Project.make!(:name => 'copy to')
      ta = TestArea.make!(:project => copy_from)

      c1 = Case.make!(:project => copy_from)
      c2 = Case.make!(:project => copy_from)
      c3 = Case.make!(:project => copy_from)
      c4 = Case.make!(:project => copy_from, :test_areas => [ta])
      c5 = Case.make!

      c1.tag_with('outer')
      c2.tag_with('outer')
      c3.tag_with('outer,inner')
      c4.tag_with('outer,inner')

      tag_ids = "#{Tag.find_by_name('outer').id},#{Tag.find_by_name('inner').id}"

      Case.copy_many_to(copy_to.id, {:user => @user, :tag_ids => tag_ids,
                        :from_test_area => ta, :from_project => copy_from})

      copy_to.reload.cases.count.should == 1
    end

  end

end
