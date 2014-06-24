require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Bugzilla do
  describe "#bugs_for_project" do
    it "should return project's bugs" do
      bt = Bugzilla.make!
      p = Project.make!(:bug_tracker => bt)
      bt.products.create!(:name => 'prod1', :external_id => 1)
      bt.products.create!(:name => 'prod2', :external_id => 2)
      bt.products.create!(:name => 'prod3', :external_id => 3)
      p.bug_products << bt.products[0]
      p.bug_products << bt.products[1]

      BugSeverity.make!(:bug_tracker => bt)

      bt.bugs.create!(:name => 'bug1', :product => bt.products[0], :external_id => '1',
                      :severity => bt.severities.first, :status => 'NEW')
      bt.bugs.create!(:name => 'bug2', :product => bt.products[1], :external_id => '2',
                      :severity => bt.severities.first, :status => 'NEW')
      bt.bugs.create!(:name => 'bug2', :product => bt.products[2], :external_id => '3',
                      :severity => bt.severities.first, :status => 'NEW')
      bt.bugs.size.should == 3
      bfp = bt.bugs_for_project(p)
      bfp.size.should == 2
    end

    it "should return only bugs for specific product if user forced.." do
      bt = Bugzilla.make!
      p = Project.make!(:bug_tracker => bt)
      bt.products.create!(:name => 'prod1', :external_id => 1)
      bt.products.create!(:name => 'prod2', :external_id => 2)
      bt.products.create!(:name => 'prod3', :external_id => 3)
      p.bug_products << bt.products[0]
      p.bug_products << bt.products[1]
      p.test_areas.create!(:name => 'ta', :bug_products => [p.bug_products.first])
      user = User.make!
      user.project_assignments.create(:project_id => p.id, :group => 'TEST_ENGINEER',
                                      :test_area => p.test_areas.first,
                                      :test_area_forced => true)
      BugSeverity.make!(:bug_tracker => bt)
      bt.bugs.create!(:name => 'bug1', :product => bt.products[0], :external_id => '1',
                      :severity => bt.severities.first, :status => 'NEW')
      bt.bugs.create!(:name => 'bug2', :product => bt.products[1], :external_id => '2',
                      :severity => bt.severities.first, :status => 'NEW')
      bt.bugs.create!(:name => 'bug2', :product => bt.products[2], :external_id => '3',
                      :severity => bt.severities.first, :status => 'NEW')

      bt.bugs_for_project(p,user).should == [bt.bugs.first]
    end

  end

  it "#to_tree should return necessary data" do
    bt = Bugzilla.make!
    result = bt.to_tree
    result.size.should == 2
    result.should have_key(:id)
    result.should have_key(:name)
  end

  it "#to_data should return necessary data" do
    bt = Bugzilla.make!
    result = bt.to_data
    result.size.should == 11
    result.should have_key(:id)
    result.should have_key(:type)
    result.should have_key(:name)
    result.should have_key(:base_url)
    result.should have_key(:db_host)
    result.should have_key(:db_port)
    result.should have_key(:db_name)
    result.should have_key(:db_user)
    result.should have_key(:db_passwd)
    result.should have_key(:bug_products)
    result.should have_key(:sync_project_with_classification)
  end

  it "#logger should create a new logger" do
    bt = Bugzilla.new
    flexmock(Import::ImportLogger).should_receive(:new).once.and_return(
      flexmock('logger', :markup= => true))
    2.times {bt.instance_eval('logger')} # check that new called only once
  end

  describe "#products_for_project" do
    it "#should return product info if project has no test area assoc." do
      bt = Bugzilla.make!
      p = Project.make!(:bug_tracker => bt)
      bt.products.create!(:name => 'foo', :external_id => '1')
      bt.products.create!(:name => 'bar', :external_id => '2')
      bt = flexmock(bt, :products_for_classification => bt.products)

      data = bt.products_for_project(p)
      data.size.should == 2
      data[0].should == {:bug_product_id => bt.products[0].id,
                         :bug_product_name => bt.products[0].name,
                         :included => false}
      data[1].should == {:bug_product_id => bt.products[1].id,
                         :bug_product_name => bt.products[1].name,
                         :included => false}
    end

    it "#should return also test area info if project has a test area assoc." do
      bt = Bugzilla.make!
      p = Project.make!(:bug_tracker => bt)
      bt.products.create!(:name => 'foo', :external_id => '1')
      bt.products.create!(:name => 'bar', :external_id => '2')
      bt = flexmock(bt, :products_for_classification => bt.products)
      p.bug_products << bt.products[0]
      p.bug_products << bt.products[1]
      p.test_areas.create!(:name => 'ta1', :bug_products => [bt.products[0]])

      data = bt.products_for_project(p)
      data.size.should == 2
      data[0].should == {:bug_product_id => bt.products[0].id,
                         :bug_product_name => bt.products[0].name,
                         :included => true,
                         :test_area_id => p.test_areas.first.id,
                         :test_area_name => p.test_areas.first.name}
      data[1].should == {:bug_product_id => bt.products[1].id,
                         :bug_product_name => bt.products[1].name,
                         :included => true}
    end

  end

  it "#refresh! should call inits" do
    bt = flexmock(Bugzilla.make!)
    bt.should_receive(:init_products).with(true).once
    bt.should_receive(:init_severities).with(true).once
    bt.should_receive(:init_components).with(true).once
    bt.refresh!
  end

  describe "#fetch_bugs" do
    it "should create a new bug" do
      bugs = Bugzilla::MockDB::MockResult.new([{'bug_severity' => 'sev_val',
                                                'product_id' => '15',
                                                'component_id' => '8',
                                                'bug_id' => 'new_bug'}])
      mock_db = flexmock(Bugzilla::MockDB.new,
                         :get_bug_ids_for_products => ['new_bug'])
      bt = flexmock(Bugzilla.make!, :active_product_ids => ['1', '15'],
                    :db => mock_db)

      prod = BugProduct.make!(:bug_tracker => bt, :external_id => '15')
      BugComponent.make!(:bug_product => prod, :external_id => '8')

      mock_db.should_receive(:bugzilla_severities).twice.and_return([{'value' => 'sev_val', 'id' => '123'}])
      mock_db.should_receive(:bugzilla_profiles).once.and_return([])
      mock_db.should_receive(:get_bugs).once.and_return(bugs)

      bt.fetch_bugs
      bt.bugs.find_by_external_id('new_bug').should_not be_nil
    end
  end


end
