require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe RequirementsController do

  it "#index should call get_tagged_items" do
    log_in
    controller.should_receive(:get_tagged_items).once.\
      with(Requirement).and_return('ok')
    get 'index'
  end

  it "#destroy should call toggle on requirement" do
    log_in
    req = flexmock('requirement', :id => 1, :deleted => false)
    req.should_receive(:deleted=).once.with(true)
    req.should_receive(:archived=).once.with(false)
    req.should_receive(:save!).once

    flexmock(Requirement).should_receive(:find).once.and_return(req)
    delete 'destroy', :id => 1
  end

  it "#create should create a new req" do
    log_in
    atts = {:att => 'val', 'cases' => [], 'tag_list' => 'foo,bar'}
    atts_wo_cases = {:att => 'val'}
    atts_in_json = ActiveSupport::JSON.encode(atts)
    flexmock(controller).should_receive(:include_users_test_area).once
    flexmock(Project).should_receive(:find).with('proj_id').and_return(
      flexmock('project', :id => 'proj_id')).once

    flexmock(ActiveSupport::JSON).should_receive(:decode).with(atts_in_json).\
      and_return(atts).once

    new_req = flexmock('req', :id => 1)

    flexmock(Requirement).should_receive(:create_with_cases!).once.with(
      atts_wo_cases.merge({:project_id => 'proj_id',:created_by => @user.id}),
      [], 'foo,bar').and_return(new_req)

    post 'create', {:project_id => 'proj_id', :data => atts_in_json}
  end

  it "#update should update req's attributes" do
    log_in
    atts = {:att => 'val', 'cases' => [], 'tag_list' => "foo,bar"}
    atts_wo_cases = {:att => 'val'}
    atts_in_json = ActiveSupport::JSON.encode(atts)

    flexmock(ActiveSupport::JSON).should_receive(:decode).with(atts_in_json).\
      and_return(atts).once

    req = flexmock('requirement', :cases => [], :id => 1)
    req.should_receive(:update_with_cases!).once.with(atts_wo_cases, [], 'foo,bar')

    flexmock(Requirement).should_receive(:find).once.with(['req_id']).\
      and_return(req)

    put 'update', {:id => 'req_id', :data => atts_in_json}
  end

end
