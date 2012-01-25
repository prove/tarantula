module Report

=begin rdoc

Test efficiency.

=end
class TestEfficiency < Report::Base
  
  def initialize(project_id, 
                 test_area_id,
                 test_object_ids,
                 sdate=nil,
                 edate=nil)
    super()
    @name = "Test Efficiency"
    @options = { :project_id => project_id,
                 :test_area_id => test_area_id,
                 :test_object_ids => test_object_ids,
                 :sdate => sdate,
                 :edate => edate }
  end
  
  protected
  
  def do_query
    h1 @name
    pad 50
    
    add_subreport MTBF.new(@options[:project_id], @options[:test_object_ids],
                   @options[:test_area_id], @options[:sdate], @options[:edate])
    page_break
    
    add_subreport DailyFailedCases.new(@options[:project_id], 
      @options[:test_object_ids], @options[:test_area_id], @options[:sdate],
      @options[:edate])
    page_break
    
    add_subreport WeeklyEfficiency.new(@options[:project_id], 
        @options[:test_object_ids], @options[:test_area_id], @options[:sdate],
        @options[:edate])
    page_break
    
    add_subreport BugFindings.new(@options[:project_id], 
        @options[:test_object_ids], @options[:test_area_id], @options[:sdate],
        @options[:edate])
  end
  
end

end # module Report
