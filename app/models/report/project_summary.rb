module Report

=begin rdoc

Report: project summary

=end
class ProjectSummary < Report::Base

  def initialize(project_id, test_area_id)
    super()
    @options = {:project_id => project_id,
                :test_area_id => test_area_id}
  end

  protected

  def do_query
    columns = ActiveSupport::OrderedHash.new
    columns[:test_area] = 'Test Area'
    columns[:current_to] = 'Current Test Object'
    columns[:rp_cov] = 'Raw Passed Coverage'
    columns[:t_cov] = 'Tested Coverage'
    columns[:defects] = 'Open Defects'

    project = Project.find_by_id(@options[:project_id])

    if !project or @options[:test_area_id]
      meta.no_content = true
      return
    end

    rows = []
    to_ids = project.test_objects.active.map(&:id)

    project.test_areas.each do |ta|
      cases = ta.cases.active
      t_cov  = Measure::tested_coverage(to_ids, cases.map(&:id), ta)
      rp_cov = Measure::raw_passed_coverage(to_ids, cases.map(&:id), ta)

      if !ta.bug_product_ids.empty?
        defects = ta.bug_products.map{|prod| prod.bugs.s_open(prod.bug_tracker[:type]).count}.sum
      else
        defects = "(no product)"
      end
      to = ta.current_test_object
      rows << {:test_area => ta.name,
               :current_to => to ? to.name : 'none',
               :rp_cov => "#{rp_cov}%",
               :t_cov => "#{t_cov}%",
               :defects => defects}
    end

    rows << {:test_area => 'WHOLE PROJECT',
             :current_to => '',
             :rp_cov => "#{Measure::raw_passed_coverage(to_ids, project.case_ids)}%",
             :t_cov => "#{Measure::tested_coverage(to_ids, project.case_ids)}%",
             :defects => project.open_bugs.size}

    h1 "Project Summary"
    t(columns, rows)
  end

end

end # module Report
