module Report

=begin rdoc

Report: bug trend

=end
class MTBF < Report::Base
  
  def initialize(project_id, test_object_ids, test_area_id=nil, 
                 sdate=nil, edate=nil, severity='normal')
    super()
    @name = "MTBF"
    @options = {:project_id => project_id,
                :test_object_ids => test_object_ids,
                :test_area_id => test_area_id,
                :sdate => sdate,
                :edate => edate,
                :severity => severity}
  end
  
  protected
  
  def do_query
    columns = ActiveSupport::OrderedHash.new
    columns[:test_object] = 'Test Object' 
    columns[:mtbf] = 'MTBF' 
    columns[:time_total] = 'Time total'
    data = []
    
    project = Project.find(@options[:project_id], :include => :bug_tracker)
    return if fatal(project.bug_tracker.nil?, "No defect tracker.")
    
    sevs = BugSeverity.at_least(@options[:severity], project.bug_tracker.id)
    return if fatal(sevs.empty?, "No severities.")
    
    if @options[:test_object_ids]
      tos = TestObject.ordered.find(:all, 
              :conditions => {:id => @options[:test_object_ids]})
    else
      tos = TestObject.find_by_dates(@options[:project_id], 
              @options[:sdate], @options[:edate])
    end
    
    bugs_severe_enough = sevs.map(&:bug_ids).flatten
    
    if ta = TestArea.find_by_id(@options[:test_area_id])
      ta_eids = ta.execution_ids
    else
      ta_eids = nil
    end
    
    tos.each do |to|
      eids = to.executions.active.map(&:id)
      eids = (eids & ta_eids) if ta_eids
      conds = ["execution_id IN (:eids)", {:eids => eids}]
      
      unless @options[:test_object_ids]
        conds[0] += " and DATE(executed_at) >= :sdate and DATE(executed_at) <= :edate"
        conds[1].merge!({:sdate => @options[:sdate], :edate => @options[:edate]})
      end
      
      total = CaseExecution.sum(:duration, :conditions => conds)
      
      fail_count = CaseExecution.count(
              :joins => [:step_executions],
              :conditions => [conds[0]+" and step_executions.bug_id IN (:bse)",
                              conds[1].merge({:bse => bugs_severe_enough})])
      
      data << {:test_object => to.name,
               :mtbf => fail_count == 0 ? 'No fails' : \
                                          (total / fail_count).to_duration,
               :time_total => total.to_duration}
    end
    
    h1 "Mean Time Between Failure"
    show_params(['Test Area',         ta],
                ['Test Object',       @options[:test_object_ids] ? \
                                        tos.map(&:name).join(', ') : nil],
                ['Start Date',        @options[:sdate]],
                ['End Date',          @options[:edate]],
                ['Severity at least', @options[:severity]])
    t(columns, data)
  end
  
end

end # Module Report
