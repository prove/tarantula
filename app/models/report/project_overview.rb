module Report

=begin rdoc

Report: an overview of a project.

=end
class ProjectOverview < Report::Base
  
  def initialize(project_id, test_area_id, test_object_id, 
                 exclude_req_cov=false, priorities=nil)
    super()
    @name = "Project Overview"
    @options = {:project_id      => project_id, 
                :test_area_id    => test_area_id,
                :test_object_id  => test_object_id,
                :exclude_req_cov => exclude_req_cov,
                :priorities      => priorities}
  end
  
  protected
  
  def do_query
    columns = ActiveSupport::OrderedHash.new
    columns[:name] = 'Project'
    columns[:test_cases] = 'Test Cases'
    columns[:t_cov] = 'Tested Coverage'
    columns[:rp_cov] = 'Raw Passed Cov.'
    columns[:req_cov] = 'Req. Cov.' unless @options[:exclude_req_cov]
    
    proj = Project.find_by_id(@options[:project_id])
    test_area = proj.test_areas.find_by_id(@options[:test_area_id])
    current_to = proj.test_objects.active.find_by_id(@options[:test_object_id])
    current_to ||= proj.test_objects.active.ordered.first
    
    case_conds = ["date <= :d and priority in (:p)", 
      {:d => current_to.try(:date), 
       :p => (@options[:priorities] || Project::Priorities.map{|p| p[:value]})}]
    req_conds = ["date <= :d", {:d => current_to.try(:date)}]
    
    if test_area
      cases = test_area.cases.active.find(:all, :select => :id, :conditions => case_conds)
      reqs = test_area.requirements.active.find(:all, :conditions => req_conds)
    else
      cases = proj.cases.active.find(:all, :conditions => case_conds, :select => :id)
      reqs = proj.requirements.active.find(:all, :conditions => req_conds)
    end
    
    to_ids = proj.test_objects.active.find(:all, :conditions => ['date <= :d', {:d => current_to.try(:date)}]).map(&:id)
    
    case_ids = cases.map(&:id)
    
    t_cov  = Measure::tested_coverage(to_ids, case_ids, test_area)
    rp_cov = Measure::raw_passed_coverage(to_ids, case_ids, test_area)
    req_cov = @options[:exclude_req_cov] ? nil : Measure::requirement_coverage(reqs, to_ids, test_area)
    
    step_count = Case.step_count(case_ids)
    
    rows = [
      {:name => proj ? proj.name : 'no project',
       :test_cases => "#{cases.size} (#{step_count})",
       :t_cov => "#{t_cov}%",
       :rp_cov => "#{rp_cov}%"
      }]
    
    rows.first[:req_cov] = "#{req_cov}%" if !@options[:exclude_req_cov] and !reqs.map(&:case_ids).flatten.empty?
    
    h1 @name
    show_params(['Test Area',   test_area], 
                ['Test Object', current_to ? \
                 "#{current_to.name} (#{current_to.date})" : nil])
    t(columns, rows, :overview => true)
    text proj.description
  end
  
end

end # module Report
