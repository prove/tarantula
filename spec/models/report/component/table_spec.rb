require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe Report::Component::Table do
  def get_instance(opts={})
    Report::Component::Table.new([[:foo, 'foo'], [:bar, 'bar'], [:baz, 'baz <3']],
      [{:foo => 1, :bar => 2, :baz => '> 3'},
       {:foo => 5, :bar => 6, :baz => '--> A'}])
  end
  it_behaves_like "report component"

  it "#to_csv should return csv" do
    tbl = get_instance
    CSV.parse(tbl.to_csv, :col_sep => ';').should ==
      [['foo', 'bar', 'baz <3'], ['1','2', '> 3'], ['5','6', '--> A']]
  end

  it "#to_pdf should return pdf" do
    doc = Prawn::Document.new
    tbl = get_instance
    tbl.to_pdf(doc).should_not be_nil
  end
end
