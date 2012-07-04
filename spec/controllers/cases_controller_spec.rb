require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe CasesController do

  before(:each) do
    log_in
  end

  describe "#index" do
    it "GET should render tagged cases when tags present" do
      controller.should_receive(:get_tagged_items).and_return('tagged_items')
      get 'index', :nodes => '1'
      response.body.should == 'tagged_items'
    end

    it "GET should render all cases if test_set id and params[:all_cases]" do
      c = flexmock('mock case', :to_data => 'case data')
      cases = flexmock('cases', :sort => [c])
      ts = flexmock('mock test set', :cases => cases)
      flexmock(TestSet).should_receive(:find).and_return(ts)

      get 'index', { :test_set_id => 1, :allcases => 'true' }

      response.body.should == ['case data'].to_json
    end

    it "GET should render test set's cases with filter if test_set_id" do
      ts = TestSet.make!
      c = Case.make!(:position => 1)
      ts.cases << c
      
      get 'index', { :test_set_id => ts.id }
      response.body.should == [c.to_tree.merge(:order => 1)].to_json
    end
  end

  it "#create should create a new case" do
    mock_step = flexmock('mocked step')
    mock_assoc = flexmock('mock assoc')
    mock_case = flexmock('mocked case', :id => 1, :steps => mock_assoc)

    flexmock(Case).should_receive(:create_with_steps!).once.\
      and_return mock_case

    params = { :data => { :title => 'foo',
                          :steps => [{ :action => 'a', :result => 'r'}],
                          :tag_list => "tag_list"}.to_json,
              }
    post 'create', params
  end

  it "#create with params[:case_ids] should copy cases" do
    mock_case = flexmock('case')
    ta = flexmock('test area')
    flexmock(@user).should_receive(:test_area).once.and_return(ta)
    flexmock(Case).should_receive(:copy_many_to).once.with('1',
      {:case_ids       => '1,2,3',
       :tag_ids        => nil,
       :from_test_area => ta,
       :to_test_areas  => 'TA_ID',
       :user           => @user,
       :from_project   => @project})

    post 'create', {:project_id => '1', :case_ids => "1,2,3", :test_area_ids => 'TA_ID'}
  end

  it "#create with params[:tag_ids] should copy cases" do
    mock_case = flexmock('case')
    ta = flexmock('test area')
    flexmock(@user).should_receive(:test_area).once.and_return(ta)
    flexmock(Case).should_receive(:copy_many_to).once.with('1',
      {:case_ids       => nil,
       :tag_ids        => '1,2',
       :from_test_area => ta,
       :to_test_areas  => 'TA_ID',
       :user           => @user,
       :from_project   => @project})

    post 'create', {:project_id => '1', :tag_ids => "1,2", :test_area_ids => 'TA_ID'}
  end


  describe "#destroy" do
    it "should set deleted flag on a case" do
      mock_case = flexmock('mock case', :id => 1, :deleted => false)
      mock_case.should_receive(:toggle_deleted).once
      flexmock(Case).should_receive(:find).once.and_return [mock_case]

      post 'destroy', :id => 1, :confirm => 'true'
      response.body.should == '[1]'
    end

    it "should call #raise_if_delete_needs_confirm if no confirm" do
      mock_case = flexmock('mock case', :id => 1, :deleted => false)
      mock_case.should_receive(:toggle_deleted).once
      mock_case.should_receive(:raise_if_delete_needs_confirm).once
      flexmock(Case).should_receive(:find).once.and_return [mock_case]

      post 'destroy', :id => 1, :confirm => ''
      response.body.should == '[1]'
    end
  end

  describe "#update" do
    it "should update cases attributes" do
      data = {'foo' => 'bar'}
      tcase = flexmock('case', :id => 1)
      tcase.should_receive(:update_with_steps!).once
      flexmock(Case).should_receive(:find).once.and_return(tcase)
      put 'update', {:project_id => 1, :id => 1, :data => data.to_json}
    end

    it "should update case version of case_execution if @data[:update_case_execution]" do
      data = {'foo' => 'bar', 'update_case_execution' => '9'}
      tcase = flexmock('case', :id => 1)
      tcase.should_receive(:update_with_steps!).once.with(
        {:foo => 'bar', :project_id => @project.id, :updated_by => @user.id},
        nil, nil, '9')
      flexmock(Case).should_receive(:find).once.and_return(tcase)
      put 'update', {:project_id => 1, :id => 1, :data => data.to_json}
    end

  end

end
