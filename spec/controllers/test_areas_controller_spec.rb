require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe TestAreasController do
  describe "#index" do
    it "should list project's default tags" do
      log_in
      proj = flexmock('project')
      flexmock(Project).should_receive(:find).once.and_return(proj)
      flexmock(@user).should_receive(:test_area).once.with(proj)
      
      ta = flexmock('test area', :to_tree => 'tree')
      proj.should_receive(:test_areas).once.and_return([ta])
      
      get 'index', {:project_id => 1}
    end
    
    it "should mark selected tag" do
      log_in
      proj = flexmock('project')
      flexmock(Project).should_receive(:find).once.and_return(proj)
      ta = flexmock('test area', :forced => false, :to_tree => {'a' => 'b'}, 
                    :id => 1)
      flexmock(@user).should_receive(:test_area).once.with(proj).\
        and_return(ta)
      
      proj.should_receive(:test_areas).once.and_return([ta])
      
      get 'index', {:project_id => 1}
      
      ActiveSupport::JSON.decode(response.body)['data'].\
        first['selected'].should == true
    end
    
    it "should list only default tag if default tag forced" do
      log_in
      proj = flexmock('project')
      flexmock(Project).should_receive(:find).once.and_return(proj)
      ta = flexmock('test area', :id => 1, :forced => true, :to_tree => {'key' => 'val'})
      flexmock(@user).should_receive(:test_area).once.with(proj).\
        and_return(ta)
      
      get 'index', {:project_id => 1}
      tdata = ActiveSupport::JSON.decode(response.body)['data'].first  
      tdata['selected'].should == true
      tdata['forced'].should == true
    end
  end

  it "#show should show user's test area" do
    log_in
    u = flexmock('user')
    u.should_receive(:test_area).once.with('proj_id')
    flexmock(User).should_receive(:find).with('user_id').once.and_return(u)
    
    get 'show', {:project_id => 'proj_id', :user_id => 'user_id'}
  end
  
  describe "#update" do

    it "should update test area" do
      log_in(:admin => false)
      u = flexmock('user')
      ta = flexmock('test area', :id => 1, :forced => false)
      u.should_receive(:test_area).once.with('proj_id').and_return(ta)
      u.should_receive(:set_test_area).once.with('proj_id', 'tid')
      flexmock(User).should_receive(:find).with('user_id').once.and_return(u)
    
      put 'update', {:project_id => 'proj_id', :user_id => 'user_id',
                     :test_area_id => 'tid'}
    end
    
    it "should not set test area if old test area forced" do
      log_in(:admin => false)
      u = flexmock('user')
      ta = flexmock('test area', :id => 1, :forced => true)
      u.should_receive(:test_area).once.with('proj_id').and_return(ta)
      u.should_receive(:set_test_area).never
      flexmock(User).should_receive(:find).with('user_id').once.and_return(u)
    
      put 'update', {:project_id => 'proj_id', :user_id => 'user_id',
                     :test_area_id => 'tid'}
    end
  end
  
end
