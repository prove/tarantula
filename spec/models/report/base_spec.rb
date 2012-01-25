require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Report::Base do
  def get_instance(query_eval="@data=[]")
    b = Report::Base.new
    code = %Q(def do_query; #{query_eval}; end)
    b.instance_eval(code)
    def b.expires_in; 0.seconds; end
    b
  end
  
  it "#to_data should call query() if no @data present" do
    r = flexmock(get_instance)
    r.should_receive(:query).once
    r.to_data
  end
  
  it "#query should just call do_query if expires_in == 0" do
    r = flexmock(get_instance)
    r.should_receive(:do_query).twice
    flexmock(Rails).should_receive(:cache).never
    2.times {r.query}
  end
  
  it "#query should call Rails.cache if expires_in > 0" do
    r = flexmock(get_instance)
    def r.expires_in; 1.minute; end
    mock_cache = flexmock('Rails.cache', :read => 1.day.from_now)
    flexmock(Rails).should_receive(:cache).at_least.and_return(mock_cache)
    flexmock(Marshal).should_receive(:load).once
    r.query
  end
  
  it "#meta should create a meta component if none present" do
    b = get_instance("h1 'header'")
    b.query
    b.to_data.size.should == 1
    b.meta.should_not be_nil
    b.to_data.size.should == 2
    b.meta
    b.to_data.size.should == 2
  end
  
  describe "#charts" do
    it "should return empty array if no chart components" do
      b = get_instance
      b.query
      b.charts.should be_empty
    end
    
    it "should define #image_post_url= on charts" do
      b = get_instance
      b.query
      b.charts.should respond_to(:image_post_url=)
    end
  end
  
  describe "#tables" do
    it "should return empty array if no tables" do
      b = get_instance
      b.query
      b.tables.should be_empty
    end
    
    it "should define #csv_export_url= on tables" do
      b = get_instance
      b.query
      b.tables.should respond_to(:csv_export_url=)
    end    
  end
  
end