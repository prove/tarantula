module Report

=begin rdoc

Report: requirement coverage

=end
class RequirementCoverage < Report::Base
  
  def initialize(project_id, test_area_id, sort_by='id', brief=false,
                 test_object_ids=nil)
    super()
    @name = "Requirement Coverage"
    @options = {:project_id      => project_id,
                :test_area_id    => test_area_id,
                :sort_by         => sort_by,
                :brief           => brief,
                :test_object_ids => test_object_ids}
  end
  
  protected
  
  def do_query
    ta = TestArea.find_by_id(@options[:test_area_id])
    
    cols = ActiveSupport::OrderedHash.new
    cols[:req_name]    = ''
    cols[:case_name]   = ''
    cols[:external_id] = 'Id'
    cols[:priority]    = 'Priority'
    cols[:cases]       = 'Cases'
    cols[:steps]       = 'Steps'
    cols[:execs]       = 'Executions'
    cols[:last_p]      = 'Last Passed'
    cols[:last_t]      = 'Last Tested'
    cols[:rp_cov]      = 'Raw Passed Coverage' 
    rows = []
    project = Project.find(@options[:project_id])
    
    if ta
      reqs = ta.requirements.active.ordered
    else
      reqs = project.requirements.active.ordered
    end
    
    if @options[:sort_by] == 'id'
      Requirement.id_sort!(reqs)
    else
      reqs.sort! do |a,b|
        if a.priority.blank? and b.priority.blank?
          0
        elsif a.priority.blank?
          1
        elsif b.priority.blank?
          -1
        else
          a.priority <=> b.priority
        end
      end
    end
    
    all_case_ids = []
    all_to_ids = project.test_objects.active.map(&:id)
    total_steps = 0
    
    reqs.each do |req|
      rp_cov = Measure::raw_passed_coverage(all_to_ids, req.case_ids, ta)
      
      rows << {:req_name    => req.name,
               :external_id => req.external_id,
               :priority    => req.priority,
               :cases       => req.cases.size,
               :steps       => req.cases.map{|c| c.steps.size}.sum,
               :rp_cov      => "#{rp_cov}%"}
      all_case_ids << req.case_ids
      req_cases = (ta ? req.cases_on_test_area(ta) : req.cases)
      req_cases.each {|c| rows << case_info(c); total_steps += c.steps.size}
    end
    all_case_ids.flatten!
    tot_rp_cov = Measure::raw_passed_coverage(all_to_ids, all_case_ids, ta)
    
    rows = [{:req_name => 'TOTAL',
             :cases    => all_case_ids.size,
             :steps    => total_steps,
             :rp_cov   => "#{tot_rp_cov}%"}] + rows
    
    h1 @name
    show_params(['Project', project], ['Test Area', ta])
    pad 40
    h2 "Summary"
    summary_table(project, ta, @options[:test_object_ids])
    
    return if @options[:brief]
    
    page_break
    h2 "Current Requirements"
    t(cols, rows, {:column_widths => {0 => 140, 1 => 140, 2 => 50, 3 => 60, 
                                      4 => 50, 5 => 50, 6 => 75, 7 => 65, 
                                      8 => 65, 9 => 65}, 
                   :collapsable => true})
  end
  
  def case_info(c)
    last_p = c.last_passed
    last_t = c.last_tested
    result = c.last_result
    
    data = { :case_name => c.name,
             :cases     => 1,
             :steps     => c.steps.size,
             :execs     => c.case_executions.count,
             :last_p    => last_p ? last_p.name : nil,
             :last_t    => last_t ? last_t.name : nil,
             :rp_cov    => result.ui,
             :priority  => c.priority_name
           }
    if result == Failed
      data.merge!({:links => {:rp_cov => {:target => 'execute', 
                                          :id => c.last_failed_exec.id}}})
    end
    data
  end
  
  def summary_table(project, ta, test_object_ids=nil)
    tob_container = ta || project
    
    if test_object_ids
      tobs = TestObject.ordered.find(:all, 
        :conditions => {:id => test_object_ids})
    else
      tobs = tob_container.test_objects.active.find(:all, :limit => 5)
    end
    tobs.reverse!
    
    cols = ActiveSupport::OrderedHash.new
    cols[:desc] = ''
    rows = [count_row   = {:desc => 'Requirements'}, 
            l_count_row = {:desc => 'Cases Linked to Requirements'},
            tc_row      = {:desc => 'Requirement Testing Coverage'}, 
            pass_row    = {:desc => 'Requirements Passed'}]
    
    tobs.each do |to|
      to_ids = tob_container.test_objects.active.find(:all, 
        :conditions => "date <= '#{to.date}'").map(&:id)
      reqs = to.requirements
      reqs = reqs.select{|r| r.test_area_ids.include?(ta.id)} if ta
      
      cols[to.name] = to.name
      count_row[to.name] = reqs.size
      tc_row[to.name] = "#{Measure.requirement_testing_coverage(reqs, to_ids, ta)}%"
      pass_row[to.name] = "#{Measure.requirement_coverage(reqs, to_ids, ta)}%"
      l_count_row[to.name] = reqs.map{|r| r.cases.size}.sum
    end
    text_options(:size => 10)
    t(cols, rows)
    text_options(:size => 8)
    text "Requirement Testing Coverage = Percentage of requirements "+
         "completely tested; requirement is completely "+
         "tested, if all related cases were run and result was either "+
         "PASSED or FAILED."
         
    text "Requirements Passed = Requirement is passed, if all related "+
         "cases have been run and result is PASSED."
         
    text "If a case wasn't run in given test object, result is fetched "+
         "from earlier test object, if any. I.e. result persists until "+
         "case is run again."
    text_options(:size => 10)
  end
  
end

end # Module Report
