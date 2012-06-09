
shared_examples_for "report component" do
  it "should respond to #to_json" do
    i = get_instance
    i.to_json
  end
  
  it "should respond to #to_pdf" do
    i = get_instance
    margin_box = flexmock('pdf margin box', :top => 0, :left => 0)
    
    pdf = flexmock('prawn pdf object',
                   :margin_box => margin_box,
                   :text       => true,
                   :table      => true,
                   :pad_bottom => true,
                   :header     => true)
    
    i.to_pdf(pdf)
  end
  
end
