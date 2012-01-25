module Report

=begin rdoc

Report: Weekly Efficiency

=end
class WeeklyEfficiency < Report::Base
  def initialize(project_id, 
                 test_object_ids,
                 test_area_id=nil,
                 sdate=nil, 
                 edate=nil)
    super()
    @name = "Weekly Efficiency"
    @options = { :project_id      => project_id,
                 :test_object_ids => test_object_ids,
                 :test_area_id    => test_area_id,
                 :sdate           => sdate,
                 :edate           => edate }
  end
  
  protected
  
  def do_query
    h1 @name
    project = Project.find(@options[:project_id])
    bt = project.bug_tracker
    return if fatal(bt.nil?, 'No defect tracker.')
    
    tobs = TestObject.find(:all, :conditions => {:id => @options[:test_object_ids]})
    tobs = TestObject.find_by_dates(@options[:project_id], \
            @options[:sdate], @options[:edate]) if tobs.empty?
    ta = TestArea.find_by_id(@options[:test_area_id])
    eids = tobs.map(&:execution_ids).flatten.uniq
    eids &= ta.execution_ids if ta
    
    if @options[:sdate] and @options[:edate]
      range = (@options[:sdate].beginning_of_week)..(@options[:edate].end_of_week)
    else
      r = TestObject.active_date_range(tobs)
      return if fatal(r.nil?, 'No data')
      range = (r.first.beginning_of_week)..(r.last.end_of_week)
    end
    
    bugs = Bug.all_linked(project, tobs, ta, false,
      ["DATE(case_executions.executed_at) >= :sdate and DATE(case_executions.executed_at) "+
       "<= :edate and bugs.reported_via_tarantula = 1", 
       {:sdate => range.first, :edate => range.last}])
    
    rows = []
    day = range.first
    
    while day < range.last do
      row = {}
      conds = ["executions.id in (:eids) and DATE(executed_at) >= :sd "+
               "and DATE(executed_at) <= :ed", 
               {:eids => eids, :sd => day, :ed => day.end_of_week}]
      
      week_bugs = bugs.select do |b| 
        se = b.step_executions.find(:first, :joins => {:case_execution => :execution}, 
                                    :conditions => conds)
        !se.nil?
      end
      hours = CaseExecution.sum(:duration, :joins => :execution, :conditions => conds).to_f / 3600
      
      row = {:week => day.cweek, 
             :hours => hours > 0 ? sprintf('%.2f', hours) : '', 
             :defects => week_bugs.size,
             :h_per_d => week_bugs.size > 0 ? sprintf('%.2f', hours / week_bugs.size) : ''}
      
      week_bugs.each{|b| row[b.severity.name] ||= 0; row[b.severity.name] += 1}
      
      rows << row
      day += 1.week
    end
    
    cols = ActiveSupport::OrderedHash.new
    cols[:week] = 'Week'
    cols[:hours] = 'Hours'
    cols[:defects] = 'Defects Found'
    cols[:h_per_d] = 'Hours / Defect'
    bt.severities.ordered.each{|sev| cols[sev.name] = sev.name}
    
    show_params(['Project', project],
                ['Test object', @options[:test_object_ids] ? \
                                  tobs.map(&:name).join(', ') : nil],
                ['Test Area',   ta],
                ['Start Week',  @options[:sdate] ? range.first.cweek : nil],
                ['End Week',    @options[:edate] ? range.last.cweek : nil])
    t(cols, rows, :column_widths => {0 => 50, 2 => 70, 3 => 70})
  end
  
end

end # module Report
