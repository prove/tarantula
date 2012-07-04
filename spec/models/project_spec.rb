require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "#{Rails.root}/lib/attsets/spec/shared/attachment_host_spec.rb"

describe Project do
  def get_instance(atts={})
    c = Project.make!(atts)
  end

  it_behaves_like "attachment host"
  
  it "#to_tree should return necessary data" do
    p = Project.make!
    keys = p.to_tree.keys
    keys.size.should == 5
    keys.should include(:text)
    keys.should include(:dbid)
    keys.should include(:leaf)
    keys.should include(:deleted)
    keys.should include(:cls)
  end
  
  it "#to_data should return necessary data" do
    p = Project.make!
    data = p.to_data
    data.should have_key(:assigned_users)
    data.should have_key(:name)
    data.should have_key(:description)
    data.should have_key(:deleted)
    data.should have_key(:id)
    data.should have_key(:library)
    data.should have_key(:test_areas)
    data.should have_key(:bug_tracker_id)
    data.keys.size.should == 8
  end
  
  it ".create_with_assignments! should create with assignments and tags" do
    p = flexmock('project', :id => 6)
    p.should_receive(:set_test_areas).once.with('test_area')
    p.should_receive(:set_bug_products).once.with('prods')
    p.should_receive(:set_users).once.with([{'group' => 'g', 'login' => 'l'}])
    
    flexmock(Project).should_receive(:create!).once.with({:att => 'val'}).\
      and_return(p)
    
    Project.create_with_assignments!(
      {:att => 'val'}, [{'group' => 'g', 'login' => 'l'}], 'test_area', 'prods')
  end
  
  describe "#update_with_assignments!" do
    it "should update attributes, assignments, and tags" do
      p = flexmock(Project.new, :id => 6)
      u = flexmock('user')
      u.should_receive('project_assignments.create!').once.with(
        {:project_id =>  6, :group => 'G', :test_area => nil,
         :test_area_forced => false})
      updater = flexmock('updater', :admin? => true, 
                         :allowed_in_project? => true)
      flexmock(User).should_receive(:find).once.and_return(u)
      p.should_receive(:update_attributes!).once.with('att' => 'val')
      p.should_receive('assignments.delete_all').once
      p.should_receive(:set_test_areas).once.with('test_area')
      p.should_receive(:set_bug_products).once.with('prods')
     
      p.update_with_assignments!(updater, {'att' => 'val'}, 
        [{'group' => 'g', 'login' => 'l'}], 'test_area', 'prods')
    end
    
    it %Q(should not allow a user to change his group in a project 
          where he's not a manager) do
      p = Project.make!
      p2 = Project.make!
      u = User.make!
      u.project_assignments.create(:project => p, :group => 'MANAGER')
      u.project_assignments.create(:project => p2, :group => 'TEST_DESIGNER')
      
      lambda { 
        p2.update_with_assignments!(u, p2.attributes,
          ['login' => u.login, 'group' => 'MANAGER'], 'areas', 'prods')
      }.should raise_error(RuntimeError, "At least manager rights required!")
    end
    
    it "should not let manager change project's name" do
      p = Project.make!(:name => 'foo')
      u = User.make!
      u.project_assignments.create(:project => p, :group => 'MANAGER')
      lambda { 
        p.update_with_assignments!(u, {:name => 'bar'},
          ['login' => u.login, 'group' => 'MANAGER'], '', [])
      }.should raise_error(RuntimeError, "Only admin can change project's name!")
    end
    
    it "should guarantee that updater does not lose her rights" do
      
    end
  end
  
  describe "#purge" do
    it "should destroy all deleted records" do
      p = Project.make!
      flexmock(Case).should_receive(:destroy_all).once.with(
        {:project_id => p.id, :deleted => true})
      flexmock(Execution).should_receive(:destroy_all).once.with(
        {:project_id => p.id, :deleted => true})
      flexmock(Requirement).should_receive(:destroy_all).once.with(
        {:project_id => p.id, :deleted => true})
      flexmock(TestSet).should_receive(:destroy_all).once.with(
        {:project_id => p.id, :deleted => true})
      flexmock(TestObject).should_receive(:destroy_all).once.with(
        {:project_id => p.id, :deleted => true})
      p.purge!
    end
    
    it "should not delete undeleted records (complex scenario)" do
      # case, execution, req, test set
      p = Project.make!
      ts = TestSet.make!(:project => p, :deleted => true)
      c = Case.make!(:project => p, :position => 1)
      ts.cases << c
      deleted = [Case.make!(:project => p, :deleted => true),
                 Execution.make!(:project => p, :deleted => true,
                                 :test_object => TestObject.make!),
                 Requirement.make!(:project => p, :deleted => true),
                 ts]
      not_deleted = [c,
                     Execution.make!(:project => p),
                     Requirement.make!(:project => p),
                     TestSet.make!(:project => p)]
      p.purge!
      deleted.each do |r|
        r.class.find_by_id(r.id).should be_nil
      end
      not_deleted.each do |r|
        r.reload.deleted.should == false
      end
    end
    
  end
  
  describe "#set_bug_products" do
    it "should clear old products" do
      p = flexmock(Project.make!, :reset_last_fetched => true)
      bt = Bugzilla.make!
      
      p.bug_products.create!(:name => 'prod1', :external_id => 'eid',
                             :bug_tracker => bt)
      p.bug_products.size.should == 1
      p.set_bug_products []
      p.bug_products.size.should == 0
    end
    
    it "should set new products" do
      p = Project.make!
      bt = Bugzilla.make!
      bt.products.create!(:name => 'prod1', :external_id => 'eid',
                          :bug_tracker => bt)
      
      p.set_bug_products [{:bug_product_id => bt.products.first.id}]
      p.bug_products.first.should == bt.products.first
    end
    
    it "should set test area -> bug product dependencies" do
      p = Project.make!
      p.test_areas.create!(:name => 'ta')
      bt = Bugzilla.make!
      bt.products.create!(:name => 'prod1', :external_id => 'eid',
                          :bug_tracker => bt)
      
      p.set_bug_products [{:bug_product_id => bt.products.first.id,
                           :test_area_name => 'ta'}]
      p.test_areas.first.reload.bug_products.should == [bt.products.first]
    end
    
    it "should also reset test area -> bug product dependencies" do
      p = Project.make!
      bt = Bugzilla.make!
      bt.products.create!(:name => 'prod1', :external_id => 'eid',
                          :bug_tracker => bt)
      p.test_areas.create!(:name => 'ta', :bug_products => [bt.products.first])
      
      p.set_bug_products [{:bug_product_id => bt.products.first.id,
                           :test_area_name => ''}]
      p.test_areas.first.bug_products.should be_empty
    end
    
    it "should reset_last_fetched on tracker if products changed (1)" do
      bt = Bugzilla.make!
      p = Project.make!
      p.bug_tracker = bt

      bt.products.create!(:name => 'prod1', :external_id => 'eid',
                          :bug_tracker => bt)
                    
      flexmock(bt).should_receive(:reset_last_fetched).once
      p.set_bug_products [{:bug_product_id => bt.products.first.id,
                           :test_area_name => ''}]      
    end
    
    it "should reset_last_fetched on tracker if products changed (2)" do
      bt = Bugzilla.make!
      p = Project.make!
      p.bug_tracker = bt
      
      bt.products.create!(:name => 'prod1', :external_id => 'eid',
                          :bug_tracker => bt)
      
      p.set_bug_products [{:bug_product_id => bt.products.first.id,
                           :test_area_name => ''}]
      
      flexmock(bt).should_receive(:reset_last_fetched).once
      p.set_bug_products []
    end
    
    it "should reset_last_fetched on tracker if products changed (3)" do
      bt = Bugzilla.make!
      p = Project.make!
      p.bug_tracker = bt
      
      bt.products.create!(:name => 'prod1', :external_id => 'eid',
                          :bug_tracker => bt)
      bt.products.create!(:name => 'prod2', :external_id => 'eid2',
                          :bug_tracker => bt)
      
      p.set_bug_products [{:bug_product_id => bt.products.first.id,
                           :test_area_name => ''}]
      
      flexmock(bt).should_receive(:reset_last_fetched).once
      p.set_bug_products [{:bug_product_id => bt.products[1].id,
                           :test_area_name => ''}]
    end
    
    it "should not reset_last_fetched on tracker if products not changed" do
      bt = Bugzilla.make!
      p = Project.make!
      p.bug_tracker = bt
      
      bt.products.create!(:name => 'prod1', :external_id => 'eid',
                          :bug_tracker => bt)
      p.set_bug_products [{:bug_product_id => bt.products.first.id,
                           :test_area_name => ''}]
      
      flexmock(bt).should_receive(:reset_last_fetched).never
      p.set_bug_products [{:bug_product_id => bt.products.first.id,
                           :test_area_name => ''}]      
    end
    
    it "should set same products to different areas" do
      p = Project.make!
      p.test_areas.create!(:name => 'ta')
      p.test_areas.create!(:name => 'ta2')
      bt = Bugzilla.make!
      bt.products.create!(:name => 'prod1', :external_id => 'eid',
                          :bug_tracker => bt)
      
      p.set_bug_products [{:bug_product_id => bt.products.first.id,
                           :test_area_name => 'ta'},
                          {:bug_product_id => bt.products.first.id,
                           :test_area_name => 'ta2'}]
                           
      p.test_areas[0].reload.bug_products.should == [bt.products.first]
      p.test_areas[1].reload.bug_products.should == [bt.products.first]
      p.bug_products.should == [bt.products.first]
    end
    
    it "should not set same product twice on test area" do
      p = Project.make!
      ta = p.test_areas.create!(:name => 'ta')
      bt = Bugzilla.make!
      bt.products.create!(:name => 'prod1', :external_id => 'eid',
                          :bug_tracker => bt)
      
      p.set_bug_products [{:bug_product_id => bt.products.first.id,
                           :test_area_name => 'ta'},
                          {:bug_product_id => bt.products.first.id,
                           :test_area_name => 'ta'}]
      ta.bug_products.all.should == [bt.products.first]
      p.bug_products.all.should == [bt.products.first]
    end
    
  end
  
  describe "#set_test_areas" do
    it "should set test areas from csv" do
      p = Project.make!
      p.set_test_areas('ta1,ta2,foo bar')
      p.test_areas.size.should == 3
    end
    
    it "should remove previous test areas" do
      p = Project.make!
      p.test_areas.create!(:name => 'ta1')
      p.set_test_areas('foo, bar')
      p.reload
      p.test_areas.size.should == 2
      p.test_areas.find_by_name('ta1').should be_nil
    end
    
  end
  
  describe "#set_users" do
    
  end
  
  
end
