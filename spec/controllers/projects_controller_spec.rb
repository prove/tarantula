require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe ProjectsController do
  
  describe "#index" do
    it "should list projects" do
      log_in(:admin => false)
      mock_proj = flexmock('project', :to_tree => :a_tree, :id => 1)
      flexmock(@user).should_receive('projects.find').once.and_return(
        [mock_proj])

      get 'index'
      response.body.should == [:a_tree].to_json
    end
    
    it "should list all projects for admin" do
      log_in(:admin => true)
      mock_proj = flexmock('project', :to_tree => :a_tree, :id => 1)
      flexmock(Project).should_receive(:find).and_return([mock_proj])
      
      get 'index'
      response.body.should == [:a_tree].to_json
    end    
  end
  
  
  it "#deleted should return deleted projects" do
    log_in(:admin => false)
    mock_proj = flexmock('project', :to_tree => :a_tree, :id => 1)
    flexmock(@user).should_receive('projects.deleted').once.and_return(
      [mock_proj])
      
    get 'deleted'
    response.body.should == [:a_tree].to_json      
  end
  
  it "#deleted should call purge! when request.delete?" do
    log_in(:admin => true)
    mock_proj = flexmock('project')
    mock_proj.should_receive(:purge!).once
    flexmock(Project).should_receive(:find).once.and_return(mock_proj)
    
    delete 'deleted', :id => 1
  end
  
  it "#create should call create_with_assignments!" do
    log_in
    data = {:test_areas => 'ta', :bug_products => 'prods', 
            :assigned_users => 'users', :att => 'val'}
    
    flexmock(Project).should_receive(:create_with_assignments!).once.with(
      {'att' => 'val'}, 'users', 'ta', 'prods').and_return(flexmock('project', :id => 1))
    
    post 'create', :data => data.to_json
  end
  
  it "#update should call update_with_with_assignments!" do
    log_in
    data = {:test_areas => 'ta', :bug_products => 'prods', 
            :assigned_users => 'users', :att => 'val'}
    
    proj = flexmock('project', :id => 1)
    proj.should_receive(:update_with_assignments!).once.with(
      @user, {'att' => 'val'}, 'users', 'ta', 'prods')
    flexmock(Project).should_receive(:find).once.with('1').and_return(proj)
    
    put 'update', :id => 1, :data => data.to_json
  end
  
  describe "#products" do
    it "should show products for this project" do
      log_in
      bt = flexmock('bug tracker')
      proj = flexmock('project', :bug_tracker => bt)
      prod = flexmock('bug product', :to_data => 'foo')
    
      flexmock(Project).should_receive(:find).and_return(proj)
    
      get 'products', :id => 1
    end
  end
  
  
end
