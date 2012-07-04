module Report

=begin rdoc

Report: an overview of a project.

=end
class Status < Report::Base
  
  def initialize(project_id, test_objects=[], test_area_id=nil)
    super()
    @name = "Status"
    @options = {:project_id => project_id,
                :test_objects => test_objects,
                :test_area_id => test_area_id}
  end
  
  def pdf_options
    opts = {:opts_for_new => {:page_layout => :landscape}}
    
    img_path = "#{Rails.root}/public/images/customer_logo.png"
    
    if File.exists?(img_path)
      init = Proc.new do |pdf|
        pdf.footer([pdf.margin_box.left, pdf.margin_box.bottom-5]) do
          pdf.image img_path, {:position => :center, :width => 80}
        end
      end
      opts.merge!({:init => init})
    end
    opts
  end
  
  
  protected
  
  def do_query
    project = Project.find(@options[:project_id])
    test_objects = TestObject.ordered.find(@options[:test_objects])
    test_area = TestArea.find_by_id(@options[:test_area_id])
    
    rto = ResultsByTestObject.new(@options[:project_id], 
      @options[:test_objects], 
      Project::Priorities.map{|p| p[:value]}, @options[:test_area_id])
    
    text_options(:size => 10)
    pad 100
    h1   "Project: #{project.name}"
    h1   "Status Report"
    
    text_options :align => :center
    h3   "Test Area: #{test_area ? test_area.name : 'All'}"
    h3   "dd.mm.yyyy", true
    h3   "Test Co-ordinator Name", true
    text_options :align => :left
    page_break
    
    h1   "Summary"
    show_params ['Project', project]

    h2   "Conclusion"
    text %Q(\
[Testing coordinator writes]
- Testing status
- Testing achievements
- Product maturity in testing pov.), true

    h2   "Risks"
    text %Q(\
[Testing coordinator writes]
- Main open issues (e.g. TOP3 list)
- Changes in specifations?
- Is the implementation schedule late?
- Are the testing actions late or coverage too low?), true

    h2   "Status of testing & Challenges"
    text %Q(\
[Testing coordinator writes]
- Resource, schedule and testing environment status
- Challennging testing tasks for the next period), true
    page_break
    
    add_subreport ProjectOverview.new(@options[:project_id],
      @options[:test_area_id], test_objects.first)
    add_component(rto.components[11])
    add_component(rto.components[12])
    page_break
    
    add_subreport RequirementCoverage.new(@options[:project_id], 
      @options[:test_area_id], 'id', true, @options[:test_objects])
    pad 30
    text "", true
    page_break
    
    h1 "Testing Maturity"
    add_component(rto.components[1])
    add_component(rto.components[5])
    add_component(rto.components[6])
    text "", true
    page_break
    
    add_component(rto.components[8])
    add_component(rto.components[9])
    text "", true
    page_break
    
    bt_comps = BugTrend.new(@options[:project_id], @options[:test_area_id], :status).components
    if bt_comps.size == 2
      bt_comps.each {|c| add_component(c)}
    else
      bt_comps[0..4].each {|c| add_component(c)}
      text "", true
      bt_comps[5..8].each {|c| add_component(c)}
      text "", true
    end
    page_break
    
    h1   "Next Steps"
    show_params ['Project', project]
    text %Q(\
[Testing coordinator writes]
Main testing actions for the next period), true, :big
  end
  
end

end # module Report
