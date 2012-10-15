require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Execution do

  def get_instance(atts={})
    Execution.make!(atts)
  end

  it_behaves_like "taggable"
  it_behaves_like "date stamped"

  it "#to_tree should have necessary data" do
    data = Execution.make!.to_tree
    data.keys.should include(:text)
    data.keys.should include(:leaf)
    data.keys.should include(:dbid)
    data.keys.should include(:deleted)
    data.keys.should include(:archived)
    data.keys.should include(:cls)
    data.keys.should include(:tags)
    data.keys.size.should == 7
  end

  it "#assigned_to should return the assigned users" do
    case_execs = [flexmock('ce1', :assignee => 'u1'),
                  flexmock('ce2', :assignee => 'u1'),
                  flexmock('ce3', :assignee => 'u2')]
    e = flexmock(Execution.make!, :case_executions => case_execs)
    e.assigned_to.should == ['u1', 'u2']
  end

  it "#duration calls sum(:duration) on case executions" do
    mock_assoc = flexmock('mock case_executions assoc')
    e = flexmock(Execution.new,
                 :case_executions => mock_assoc)

    mock_assoc.should_receive(:sum).with(:duration)
    e.duration
  end
  describe ".create_with_assignments!" do
    it "should create execution and case execs with assignments" do
      ts = TestSet.make_with_cases(:cases => 50)
      c1 = ts.cases[0]
      c2 = ts.cases[1]
      to = TestObject.make!(:project => ts.project)
      atts = { :name => 'a new execution',
              :test_object => to,
              :project_id => ts.project_id,
              :created_by => 1,
              :date => Date.today }
      case_data = ts.cases.map{|c| {'id' => c.id, 'assigned_to' => rand(2),
                                    'position' => c.position,
                                    'case_version' => c.version}}

      # make some new versions of the test set here
      ts.save!
      ts.cases << [Case.make!(:project => ts.project, :position => 1),
                   Case.make!(:project => ts.project, :position => 2)]
      # alter some cases
      c1.steps << [Step.make!(:position => 1)]
      c2.steps << [Step.make!(:position => 1), Step.make!(:position => 2)]

      e = Execution.create_with_assignments!(atts, case_data, 1)
      e.case_executions.count.should == 50
      e.case_executions.each do |ce|
        test_case = ce.test_case
        test_case.revert_to(ce.case_version)
        ce.step_executions.size.should == test_case.steps.size
        ce.step_executions.map(&:step_id).should == \
          test_case.steps.map(&:id)
      end
    end

    it "should tolerate NULL positions for steps" do
      ts = TestSet.make_with_cases(:cases => 5)
      to = TestObject.make!(:project => ts.project)

      # make some null positions
      ActiveRecord::Base.connection.execute(
        "UPDATE cases_steps SET position=NULL WHERE case_id=#{ts.cases[0].id}")

      atts = { :name => 'a new execution',
               :date => Date.today,
               :test_object => to,
               :project_id => ts.project_id,
               :created_by => 1 }
      case_data = ts.cases.map{|c| {'id' => c.id, 'assigned_to' => rand(2),
                                    'position' => c.position,
                                    'case_version' => c.version}}
      e = Execution.create_with_assignments!(atts, case_data, 1)
    end
  end
  describe "#update_with_assignments!" do
    it "should update old case execs" do
      e = flexmock(Execution.make!)
      e.should_receive(:update_attributes!).once
      e.should_receive(:tag_with).once.with('a_tag')
      ce = flexmock('case exec', :[]= => nil, :each => [])
      ce.should_receive(:update_attributes!).once
      flexmock(CaseExecution).should_receive(:find).once.
        with(:first, Hash).and_return(ce)
      flexmock(CaseExecution).should_receive(:all).once.
          with(Hash).and_return([])
      e.update_with_assignments!({'some att' => 'some val'}, [{'id' => 1}], 'a_tag')
    end

    it "should create new case execs" do
      e = flexmock(Execution.make!)
      e.should_receive(:update_attributes!).once
      e.should_receive(:tag_with).once.with('a_tag')
      Case.make!(:id => 1)

      flexmock(CaseExecution).should_receive(:create_with_steps!).once
      e.update_with_assignments!({'some att' => 'some val'}, [{'id' => 1}], 'a_tag')
    end

    it "should remove old cases that are to be removed on update" do
      e = Execution.make_with_runs(:cases => 1)
      old_ce = e.case_executions.first
      old_ce.should_not be_nil

      c = Case.make!

      e.update_with_assignments!(e.attributes, [{'id' => c.id, 'position' => 1}])
      e.reload
      e.case_executions.size.should == 1
      e.case_executions.first.case_id.should == c.id
    end

    it "should accept ActiveSuport::Safebuffer as test object name" do
      e = Execution.make_with_runs(:cases => 1)
      c = Case.make!
      to = TestObject.make!(:project => e.project, :name => "TO X")
      to_name = ActiveSupport::SafeBuffer.new("TO X")
      e.update_with_assignments!(e.attributes.merge('test_object' => to_name),
                                 ['id' => c.id, 'position' => 1])
      e.test_object.should == to
    end
  end

  describe "#reposition_case_executions" do
    it "should change positions" do
      e = Execution.make_with_runs(:cases => 3)
      e.case_executions[0].update_attribute(:position, 0)
      e.case_executions[1].update_attribute(:position, 0)
      e.case_executions[2].update_attribute(:position, 0)
      e.case_executions.map(&:position).should == [0,0,0]
      e.reposition_case_executions
      e.case_executions.map(&:position).should == [1,2,3]
    end
  end

  describe "#save" do
    it "should update related cases' timestamps" do
      c = Case.make!
      stamp = c.updated_at
      sleep(1)
      ce = CaseExecution.make!(:test_case => c)
      e = Execution.create(:case_executions => [ce])
      e.save
      c.reload.updated_at.should_not == stamp
    end
  end

end
