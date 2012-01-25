module Report

=begin rdoc

Report: Daily progress.

=end
class DailyProgress < Report::Base
  
  #################################
  # a subreport
  class DayResult < Report::Base
    def initialize(project_id, test_object_id, test_area_id, date)
      super()
      @options = {:project_id => project_id,
                  :test_object_id => test_object_id,
                  :test_area_id => test_area_id,
                  :date => date.to_s}
    end
    
    protected
    def expires_in
      # ResultsReport caches
      return 0.seconds if @options[:date] == Date.today.to_s
      return 1.week # not used after one week
    end
    
    def do_query
      conds = ["executions.test_object_id = :tob AND "+
               "case_executions.executed_at <= :date AND executions.deleted=0",
              {:tob => @options[:test_object_id], 
               :date => "#{@options[:date]} 23:59:59"}]
      
      ta = TestArea.find_by_id(@options[:test_area_id])
      if ta
        eids = ta.execution_ids
        conds[0] += " and executions.id in (:eids)"
        conds[1][:eids] = eids
      end
      
      rep = Report::Results.new(@options[:project_id], conds)
      rep.query
      add_component(rep.tables.first)
    end
  end
  #################################
  
  def initialize(project_id, test_object_id, test_area_id=nil)
    super()
    @name = "Daily Progress"
    @options = {:project_id     => project_id, 
                :test_object_id => test_object_id,
                :test_area_id   => test_area_id}
  end
  
  protected
  
  def do_query
    columns = []
    vals = []
    maxes = []
    
    (-6..0).each do |i|
      date = Date.today + i
      day = DayResult.new(@options[:project_id], @options[:test_object_id],
                          @options[:test_area_id], date)
      day.query
      vals << [day.row(0)[:test_results], 
               day.row(1)[:test_results], 
               day.row(2)[:test_results], 
               day.row(3)[:test_results]]
      maxes << day.row(ResultType.all.size+1)[:cases]
      columns << date.to_s
    end
    
    h1 @name
    show_params(['Test Area',   TestArea.find_by_id(@options[:test_area_id])],
                ['Test Object', TestObject.find_by_id(@options[:test_object_id])])
    bar_stack_chart(nil, columns, 
                   [{:values => vals, 
                     :text => [Passed.rep, Failed.rep, Skipped.rep, NotImplemented.rep],
                     :colours => [Passed.color, Failed.color, Skipped.color, 
                                  NotImplemented.color]}],
                     maxes.max, :diagonal_labels)
    charts.first.set_tooltip_by_result_type
  end
  
end

end # module Report
