require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe DashboardItem do
  describe "#to_report" do
    it "should call new on the class" do
      class_name = flexmock('class name')
      class_name.should_receive('constantize.new').once
      r = DashboardItem.new(:test, 'Just a Test', class_name,
                            nil, Proc.new{|u,p| [1]})
      r.to_report(nil, nil)
    end
    
    it "should call the proc once" do
      p = flexmock('a proc')
      flexmock(p).should_receive(:call).once.and_return([1])
      r = DashboardItem.new(:test, 'Just a Test', 'Report::MyTasks',
                            nil, p)
      r.to_report(nil, nil)
    end
    
  end
end
