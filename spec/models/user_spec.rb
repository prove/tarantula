require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User do
  def get_instance(atts={})
    User.make!(atts)
  end

  it "#allowed_in_project? should tell if user is allowed in project "+
     "with given rights" do
    p = Project.make!
    u = User.make!
    u.allowed_in_project?(p, ['GUEST']).should == false

    ProjectAssignment.create(:project_id => p.id, :user_id => u.id,
                             :group => 'TEST_DESIGNER')

    u.allowed_in_project?(p, ['GUEST', 'TEST_ENGINEER']).should == false
    u.allowed_in_project?(p, ['GUEST', 'TEST_ENGINEER', 'TEST_DESIGNER']).\
      should == true
  end

  it "#to_data should return necessary data" do
    u = User.make!
    keys = u.to_data.keys
    keys.size.should ==  10
    keys.should include(:id)
    keys.should include(:description)
    keys.should include(:phone)
    keys.should include(:realname)
    keys.should include(:login)
    keys.should include(:email)
    keys.should include(:admin)
    keys.should include(:version)
    keys.should include(:time_zone)
    keys.should include(:deleted)
  end

  it "#to_tree should return necessary data" do
    u = User.make!
    keys = u.to_tree.keys
    keys.size.should == 6
    keys.should include(:dbid)
    keys.should include(:text)
    keys.should include(:leaf)
    keys.should include(:deleted)
    keys.should include(:cls)
    keys.should include(:realname)
  end

  describe "#set_test_area" do
    it "it should set test area" do
      u = User.make!
      p = Project.make!
      ta = TestArea.new(:name => 'area1')
      p.test_areas <<  ta
      p.assignments << ProjectAssignment.new(:user => u, :group => 'MANAGER')
      u.test_area(p).should == nil
      u.set_test_area(p.id, ta.id, true)
      u_ta = u.reload.test_area(p)
      u_ta.id.should == ta.id
      u_ta.forced.should == true
    end

    it "should not reset test object" do
      u = User.make!
      p = Project.make!
      to = TestObject.make!(:project => p)
      to2 = TestObject.make!(:project => p)
      ta = TestArea.make!(:project => p, :name => 'area1')
      pa = ProjectAssignment.create!(:user => u, :project => p, :test_object => to,
                                     :test_area => ta, :group => 'MANAGER')
      ta2 = TestArea.make!(:project => p, :name => 'area2')
      u.set_test_area(p.id, ta2.id)
      pa.reload
      pa.test_area.should == ta2
      pa.test_object.should == to
    end
  end

  it "#execution_tasks should create task for each user's not run execution" do
    u = User.make!
    e = flexmock('execution', 'case_executions.count' => 1)
    flexmock(Execution).should_receive(:find).once.and_return([e, e])
    flexmock(Task::Execution).should_receive(:new).twice.with(e, u, 1)
    u.execution_tasks
  end

end
