module Report

=begin rdoc

Report: A list of daily failed cases for a selected period of time.

=end
class DailyFailedCases < Report::Base
  LineColours = ['#B3964D',
                 '#006EB4',
                 '#AB9E8A',
                 '#FFD66E',
                 '#B58200',
                 '#693A00',
                 '#6A2B18',
                 '#33AF2D',]
  
  def initialize(project_id, 
                 test_object_ids,
                 test_area_id=nil,
                 sdate=nil, 
                 edate=nil)
    super()
    @name = "Daily Failed Cases"
    @options = { :project_id      => project_id,
                 :test_object_ids => test_object_ids,
                 :test_area_id    => test_area_id,
                 :sdate           => sdate,
                 :edate           => edate }
  end
  
  protected
  
  def do_query
    h1 @name
    
    tobs = TestObject.ordered.find(:all, :conditions => {:id => @options[:test_object_ids]})
    sdate, edate = @options[:sdate], @options[:edate]
    if !sdate or !edate
      range = TestObject.active_date_range(tobs)
      sdate, edate = range.first, range.last if range
    end
    
    tobs = TestObject.find_by_dates(@options[:project_id], sdate, edate) if tobs.empty?
    ta = TestArea.find_by_id(@options[:test_area_id])
    
    return if fatal((sdate.nil? or edate.nil? or tobs.blank?), "No data")
    
    conds_str = \
      "case_executions.result=:res AND executions.deleted=0 AND "+
      "DATE(case_executions.executed_at) >= '#{sdate}' AND "+
      "DATE(case_executions.executed_at) <= '#{edate}' AND "+
      "executions.id IN (:eids)"
    conds_hash = {:res => Failed}
    
    vals_arr = []
    
    tobs.each do |to|
      vals = []
      eids = to.execution_ids
      eids &= ta.execution_ids if ta
      conds_hash[:eids] = eids
      
      counts = CaseExecution.count(:conditions => [conds_str, conds_hash],
         :joins => [:test_case, :execution], 
         :group => "DATE(executed_at)")
      
      (sdate..edate).each do |d|
        c = counts.detect{|c| c[0] == d.to_s}
        vals << (c ? c[1] : 0)
      end
      
      vals_arr << vals
    end
    
    elems = []
    vals_arr.each_with_index do |vals,i|
      elems << {:values => vals,
                :colour => LineColours[(i % LineColours.size-1)],
                :text   => tobs[i].name}
    end
    
    # ---
    show_params(['Project', Project.find_by_id(@options[:project_id])],
                ['Test Area',   ta],
                ['Test Object', @options[:test_object_ids] ? \
                                  tobs.map(&:name).join(', ') : nil],
                ['Start Date',  @options[:sdate]],
                ['End Date',    @options[:edate]])
    
    c = line_chart(nil, (sdate..edate).to_a, elems,
                   vals_arr.flatten.max, :vertical_labels)
    c.limit_labels
  end
  
end

end # module Report
