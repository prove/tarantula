module Report

=begin rdoc

Report: Dashboard results.

=end
class DashboardResults < Report::Base
  
  def initialize(project_id, test_object_id, test_area_id)
    super()
    @name = "Test Result Status"
    
    @options = { :project_id     => project_id,
                 :test_object_id => test_object_id,
                 :test_area_id   => test_area_id }
  end
  
  protected
  
  def tweak_table(tbl)
    tbl.columns[:name] = 'Result'
    tbl.columns[:test_results] = 'Count'
    tbl.columns[:perc] = 'Raw Pass Rate'
    tbl.columns[:tested_pr] = 'Tested Pass Rate'
    tbl.columns.delete(:all_cases)
    p_row = tbl.data.detect{|d| d[:name] == Passed.rep}
    f_row = tbl.data.detect{|d| d[:name] == Failed.rep}
    passed = p_row[:test_results]
    failed = f_row[:test_results]
    tested_pr_p = passed.in_percentage_to(passed+failed)
    p_row[:tested_pr] = "#{tested_pr_p}%"
    f_row[:tested_pr] = "#{100-tested_pr_p}%"
    tbl.data.detect{|d| d[:name] == 'Total'}[:tested_pr] = passed + failed
  end
  
  def do_query
    project = Project.find(@options[:project_id])
    
    if ta = TestArea.find_by_id(@options[:test_area_id])
      eids = ta.executions.active.map(&:id)
    else
      eids = project.executions.active.map(&:id)
    end
    eids = [0] if eids.empty?
    conds = ["executions.test_object_id=:to_id and executions.id in (:eids)", 
            {:to_id => (@options[:test_object_id] || 0), :eids => eids}]
    
    rep = Results.new(@options[:project_id], conds)
    rep.query
    
    h1 @name
    show_params(['Test Area', ta], ['Test Object', \
                 TestObject.find_by_id(@options[:test_object_id])])
    tbl = rep.tables.first
    tbl.data.reject!{|d| d[:name] == 'project total'}
    bar_chart_results(nil, [[:test_results, "Result"]], tbl.data.dup)
    tweak_table(tbl)
    
    case_ids = Case.find(:all, :select => 'DISTINCT cases.id', 
                         :joins => {:case_executions => :execution},
                         :conditions => conds).map(&:id)
    not_run_ids = Case.find(:all, :select => 'DISTINCT cases.id', 
                            :joins => {:case_executions => :execution},
                            :conditions => [conds[0]+" and case_executions.result=:r",
                                            conds[1].merge(:r => NotRun.db)]).map(&:id)
    
    add_component(tbl)
    text "Estimated duration for cases not run: #{Case.total_avg_duration(not_run_ids).to_duration}"
    text "Estimated duration: #{Case.total_avg_duration(case_ids).to_duration}"
  end
  
end

end # module Report
