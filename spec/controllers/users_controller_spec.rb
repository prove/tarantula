require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe UsersController do

  describe "#index" do
    it "should list all users if logged in as admin" do
      log_in

      p1 = Project.make!
      u1 = User.make!(:login => 'user1')
      u1.project_assignments.create!(:project => p1,
                                   :group => 'TEST_ENGINEER')
      p2 = Project.make!
      u2 = User.make!(:login => 'user2')
      u2.project_assignments.create!(:project => p2,
                                   :group => 'MANAGER')

      p3 = Project.make!
      u3 = User.make!(:login => 'user3')
      u3.project_assignments.create!(:project => p3,
                                     :group => 'TEST_DESIGNER')

      get 'index'

      response.body.include?(u1.to_tree.to_json).should == true
      response.body.include?(u2.to_tree.to_json).should == true
      response.body.include?(u3.to_tree.to_json).should == true
    end

    it "should list only users from common projects for non admin user" do
      log_in({:admin => false, :group => 'MANAGER_VIEW_ONLY'})
      p1 = Project.make!
      u1 = User.make!(:login => 'user1')
      u1.project_assignments.create!(:project => p1,
                                   :group => 'TEST_ENGINEER')
      controller.instance_variable_get(:@current_user).project_assignments.create!(:project => p1,
                                                                                 :group => 'MANAGER_VIEW_ONLY')
      p2 = Project.make!
      u2 = User.make!(:login => 'user2')
      u2.project_assignments.create!(:project => Project.last,
                                   :group => 'TEST_ENGINEER')

      get 'index'

      response.body.include?(u1.to_tree.to_json).should == true
      response.body.include?(u2.to_tree.to_json).should == false
    end

    it "should list users from given project if logged in user is included to that project." do
      log_in({:admin => false, :group => 'MANAGER_VIEW_ONLY'})
      p1 = Project.make!
      u1 = User.make!(:login => 'user1')
      u1.project_assignments.create!(:project => p1,
                                   :group => 'TEST_ENGINEER')
      controller.instance_variable_get(:@current_user).project_assignments.create!(:project => p1,
                                                                                 :group => 'MANAGER_VIEW_ONLY')
      p2 = Project.make!
      u2 = User.make!(:login => 'user2')
      u2.project_assignments.create!(:project => Project.last,
                                     :group => 'TEST_ENGINEER')

      get 'index', {:project_id => p1.id}

      response.body.include?(u1.to_tree.to_json).should == true
      response.body.include?(u2.to_tree.to_json).should == false
    end

  end

  it "#deleted should list deleted users" do
    log_in
    u = flexmock('user', :deleted => true)
    u.should_receive(:to_tree).once
    flexmock(User).\
      should_receive(:all).once.and_return([u])
    get 'deleted', {:project_id => 1}
  end

  it "#permissions should list users permissions" do
    log_in
    u = flexmock('user', :admin? => false)
    u.should_receive('project_assignments.find').once.and_return(
      flexmock('proj assignment', :to_json => ""))
    flexmock(User).should_receive(:find).once.and_return(u)
    get 'permissions', {:id => 1}
  end

  it "#create should create a new user" do
    log_in
    data = {'foo' => 'bar'}

    u = flexmock('user', :password => nil, :id => 1)
    flexmock(User).should_receive(:new).once.with(data).and_return(u)
    u.should_receive(:new_random_password).once
    u.should_receive(:save!).once

    post 'create', :data => data.to_json
  end

  it "#show should return user data" do
    log_in
    u = User.make!
    get 'show', :id => u.id
    response.body.should == {:data => [u.to_data]}.to_json
  end

  describe "#update" do
    it "should update user's own data" do
      log_in
      data = {'foo' => 'bar'}
      u = flexmock('user', :id => 1, :admin? => false)
      u.should_receive(:update_attributes!).once.with(data)
      flexmock(User).should_receive(:find).once.and_return(u)
      put 'update', {:id => @user.id, :data => data.to_json}
    end

    it "should update other user's data if admin (also admin flag)" do
      log_in
      data = {'foo' => 'bar', 'admin' => true}
      u = flexmock('user', :id => 1, :admin? => false)
      u.should_receive(:update_attributes!).once.with(data)
      flexmock(User).should_receive(:find).once.and_return(u)
      put 'update', {:id => @user.id+1, :data => data.to_json}
    end

    it "should not update other user's data if NOT admin" do
      log_in(:admin => false)
      data = {'foo' => 'bar'}
      flexmock(User).should_receive(:find).never
      put 'update', {:id => @user.id+1, :data => data.to_json}
    end

    it "should not set admin flag if current user is NOT admin" do
      log_in(:admin => false)
      data = {'foo' => 'bar', 'admin' => true}
      u = flexmock('user', :id => 1)
      u.should_receive(:update_attributes!).once.with({'foo' => 'bar'})
      flexmock(User).should_receive(:find).once.and_return(u)
      put 'update', {:id => @user.id, :data => data.to_json}
    end
    
    it "should remove admin assignments when admin rights are removed" do
      log_in
      u = Admin.make!
      p = Project.make!
      p2 = Project.make!
      ProjectAssignment.create!(:project => p, :user => u, :group => 'ADMIN')
      ProjectAssignment.create!(:project => p2, :user => u, :group => 'ADMIN')
      data = u.attributes.merge('admin' => 0)
      put 'update', {:id => u.id, :data => data.to_json}
      # now the user u should be normal non-admin user
      ProjectAssignment.where(:project_id => p.id, :user_id => u.id).\
        should be_empty
      ProjectAssignment.where(:project_id => p2.id, :user_id => u.id).\
        should be_empty
    end
    
  end

  it "#destroy should mark user deleted" do
    log_in
    u = flexmock('user', :id => 1)
    u.should_receive(:toggle!).once.with(:deleted)
    flexmock(User).should_receive(:find).once.with('1').and_return(u)
    delete 'destroy', :id => 1
  end

  it "#selected_project should change user's selected project" do
    log_in
    @user = flexmock(@user)
    @user.should_receive(:allowed_in_project?).once.with('1').and_return(true)
    proj = flexmock('project', :id => 1)
    flexmock(Project).should_receive(:find).once.with('1').and_return(proj)
    @user.should_receive(:save!).once
    put 'selected_project', {:id => 1, :project_id => 1}
  end

  it "#available_groups should list available user groups" do
    log_in
    get 'available_groups', {:id => 'current'}
  end

end
