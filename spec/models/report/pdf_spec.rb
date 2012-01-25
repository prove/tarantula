require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Report::PDF do
  it "#render should render using prawn" do
    pdf_comp = flexmock('a pdf component')
    report = flexmock('report', :components => [pdf_comp])
    doc = flexmock('prawn document', :font => true, :stroke_color= => true)
    doc.should_receive(:render).once
    pdf_comp.should_receive(:to_pdf).once.with(doc)
    flexmock(Prawn::Document).should_receive(:new).once.and_return(doc)
    
    pdf = Report::PDF.new(report)
    pdf.render
  end
end
