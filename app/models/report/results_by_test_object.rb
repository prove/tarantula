module Report

=begin rdoc

This report returns case execution results by test object.

=end
class ResultsByTestObject < Report::Base
  
  def initialize(project_id, test_object_ids, priorities, 
                 test_area_id)
    super()
    @name = "Prioritized Testing Maturity"
    @options = { :project_id         => project_id,
                 :test_object_ids    => test_object_ids,
                 :priorities         => priorities,
                 :test_area_id       => test_area_id }
  end
  
  protected
  
  def do_query
    results = []
    cumulative = []
    to_names = []
    project = Project.find(@options[:project_id])
    test_area = TestArea.find_by_id(@options[:test_area_id])
    
    if test_area
      eids = test_area.executions.active.map(&:id)
      container = test_area
    else
      eids = project.executions.active.map(&:id)
      container = project
    end
    
    tobs = [TestObject.find(@options[:test_object_ids], :order => 'date asc')].flatten
    cumulative = [[], []]
    
    tobs.each do |to|
      to_names << to.name
      to_ids = container.test_objects.active.find(:all,
        :conditions => "date <= '#{to.date}'", :select => :id).map(&:id)
      case_ids = container.cases.active.find(:all,
        :conditions => ["date <= :d and priority IN (:p)", 
        {:d => to.date, :p => @options[:priorities]}], 
        :select => :id).map(&:id)
      
      conds = ["executions.deleted=0 AND executions.archived=0 AND "+
               "test_object_id=:to_id AND "+
               "cases.priority IN (:p) AND executions.id IN (:eids)", 
               {:to_id => to.id, :p => @options[:priorities],
                :eids => eids}]
      results << Report::Results.new(@options[:project_id], conds)
      
      cumulative[0] << Measure.raw_passed_coverage(to_ids, case_ids, test_area)
      cumulative[1] << Measure.raw_passed_coverage(to_ids, case_ids, test_area, NotImplemented)
    end
    
    cols, data, data_perc = Report::Results.combine(to_names, results)
    
    # ---
    h1 @name
    show_params(['Project', project],
                ['Test Area',   TestArea.find_by_id(@options[:test_area_id])],
                ['Test Object', to_names.join(', ')],
                ['Priorities',  @options[:priorities].map{|p| 
                  Project::Priorities.detect{|pp| pp[:value] == p}[:name]}.join(', ')])
    
    h2 "Project Overview"
    po =  ProjectOverview.new(@options[:project_id], @options[:test_area_id], 
                              tobs.last, true, @options[:priorities])
    add_component(po.components[2])
    
    page_break
    h2 "Testing Coverage By Test Object"
    bar_chart_results(nil, cols, data, :diagonal_labels)    
    
    page_break
    h2 "Percentages"
    t(cols, data_perc)
    
    page_break
    h2 "Cumulative Raw Passed Coverage"
    add_component Report::OFC::Line::Multi.new(cumulative, to_names)
    text '', true
  end
  
end

end # module Report
