require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe ReportDataController do

  #Delete this example and add some real ones
  it "should return data with #show" do
    log_in
    p = Project.make!
    u = User.make!
    rdata = Report::Data.create!(:project => p, :user => u, 
                                 :key => 'foobar', :data => {:foo => 'bar'})
    
    get 'show', :project_id => p.id, :user_id => u.id, :id => rdata.key
    response.should be_success
    ActiveSupport::JSON.decode(response.body).should == {'foo' => 'bar'}
  end
  
  it "should create/update data with #create" do
    log_in
    flexmock(Report::Data).should_receive(:create!).once
    
    post 'create', :project_id => 1, :user_id => 2, 
                   :key => 'foobar', 'dippa' => 'dui'
    response.should be_success
  end
  
end
