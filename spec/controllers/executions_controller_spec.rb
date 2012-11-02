require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe ExecutionsController do
  describe "#index" do

    it "should list executions of project for user" do
      log_in(:admin => true)
      mock_exec = flexmock('execution')
      mock_exec.should_receive(:to_data).with(:brief).once
      mock_project = flexmock('project', 'executions.active.ordered.all' =>
                              [mock_exec])
      flexmock(User).should_receive(:find).and_return(@user)
      flexmock(@user).should_receive(:test_area).once
      flexmock(Project).should_receive(:find).and_return(mock_project)
      get 'index', {:project_id => 1, :user_id => 1}
    end

  end
  describe "#create" do
    it "should function with no test set" do
      log_in
      data = { :name => 'exec',
               :test_object => 'tob',
               :cases => [
                          {:id => 1, :assigned_to => nil, :position => 1},
                          {:id => 2, :assigned_to => nil, :position => 2}
                         ]
             }
      flexmock(Execution).should_receive(:create_with_assignments!).once.\
        and_return(flexmock('execution', :id => 1))
      controller.should_receive(:require_test_area).once

      post 'create', {:data => data.to_json}
    end
  end

  describe "#show" do
    it "should call to_data" do
      log_in
      exec = flexmock('execution')
      exec.should_receive(:to_data).once
      flexmock(Execution).should_receive(:find).once.and_return(exec)
      get 'show', :id => 1
    end

    it "should send csv when called with format=csv" do
      log_in
      exec = flexmock('execution')
      exec.should_receive(:to_csv).once.and_return('csv')
      flexmock(Execution).should_receive(:find).once.and_return(exec)
      get 'show', {:id => 1, :format => 'csv'}
    end
  end

  describe "#update" do
    it "should update with assignments" do
      data = {:tag_list => 'tag', :cases => 'cases'}
      log_in
      e = flexmock('execution', :id => 1)
      flexmock(Execution).should_receive(:find).once.and_return(e)
      e.should_receive(:update_with_assignments!).once.with(Hash, 'cases', 'tag')

      put 'update', {:id => 1, :data => data.to_json}
    end

    it "should update from from csv when params[:file]" do
      log_in
      e = flexmock('execution', :id => 1)
      flexmock(Execution).should_receive(:find).once.and_return(e)
      csv_import = flexmock('csv import')
      flexmock(CsvExchange::Import).should_receive(:new).once.and_return(csv_import)
      csv_import.should_receive(:process).once
      put 'update', {:id => 1, :file => 'file_contents'}
      response.should be_success
    end
  end

  describe "#destroy" do
    it "should toggle deleted attribute" do
      log_in
      e = flexmock('execution', :id => 1, :deleted => false)
      flexmock(Execution).should_receive(:find).once.and_return(e)
      e.should_receive(:update_attributes!).with({:deleted => true, :archived => false}).once

      delete 'destroy', {:id => 1}
    end
  end

  describe "#require_test_area" do
    it "should not raise if project has no test areas" do
      project = Project.make!
      ec = ExecutionsController.new
      ec.instance_eval {require_test_area({}, project)}
    end

    it "should raise if project has test areas and no matching test_area_id" do
      project = Project.make!
      project.test_areas.create! :name => 'ta'
      ec = ExecutionsController.new

      lambda {ec.instance_eval {require_test_area({'test_area_ids' => []}, project)}}.should \
        raise_error(StandardError, "Test area required!")
    end

    it "should not raise if project has test areas and matching id found" do
      project = Project.make!
      ta = project.test_areas.create! :name => 'ta'
      e = Execution.make!(:project => project)
      e.tag_with('ta')

      ec = ExecutionsController.new
      ec.instance_eval {require_test_area({'test_area_ids' => [ta.id]}, project)}
    end

  end

end
