require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../shared/report_component_spec.rb')

describe Report::Component::Table do
  def get_instance(opts={})
    Report::Component::Table.new([[:foo, 'foo'], [:bar, 'bar']], 
      [{:foo => 1, :bar => 2}, {:foo => 5, :bar => 6}])
  end
  it_should_behave_like "report component"
  
  it "#to_csv should return csv" do
    tbl = get_instance
    CSV.parse(tbl.to_csv, ';').should == [['foo', 'bar'], ['1','2'], ['5','6']]
  end
end