module Report
=begin rdoc

Report: bug findings

=end
class BugFindings < Report::Base
  
  def initialize(project_id, 
                 test_object_ids,
                 test_area_id, 
                 sdate=nil,
                 edate=nil)
    super()
    @name = "Defects Found: Tarantula Testing vs. Other Sources"
    @options = {:project_id      => project_id,
                :test_object_ids => test_object_ids,
                :test_area_id    => test_area_id,
                :sdate           => sdate,
                :edate           => edate}
  end
  
  protected
  
  # returns "YYYY/WW" for each week
  def weeks_for_date_range(range)
    weeks = []
    date = range.first.beginning_of_week
    to = range.last
    while date <= to
      weeks << "#{date.year}/#{date.cweek.to_s.rjust(2,'0')}"
      date += 7.days
    end
    weeks
  end
  
  def do_query
    project = Project.find(@options[:project_id])
    test_area = TestArea.find_by_id(@options[:test_area_id])
    return if fatal(project.bug_tracker.nil?, "No defect tracker.")
    return if fatal((test_area and test_area.bug_product_ids.empty?), 
                    "Test area not mapped to product.")
    
    if @options[:sdate] and @options[:edate]
      weeks = weeks_for_date_range(@options[:sdate]..@options[:edate])
    else
      r = TestObject.active_date_range(TestObject.find(@options[:test_object_ids]))
      return if fatal(r.nil?, 'No data')
      weeks = weeks_for_date_range(r)
    end
    
    tarantula_rep = []
    other_rep = []
    max = 0
    conds = {}
    conds.merge!({:bug_product_id => test_area.bug_product_ids}) if test_area
    
    weeks.each do |week|
      if week == "#{Date.today.year}/#{Date.today.cweek.to_s.rjust(2,'0')}"
        snapshot = project.bug_tracker
      else
        snapshot = BugTrackerSnapshot.find(:first, 
          :conditions => {:name => "Week #{week}", :bug_tracker_id => project.bug_tracker_id})
      end
      if snapshot.nil?
        tarantula_rep << 0
        other_rep << 0
        next
      end
      t_count = snapshot.bugs.count(:conditions => conds.merge({:reported_via_tarantula => true}))
      o_count = snapshot.bugs.count(:conditions => conds.merge({:reported_via_tarantula => false}))
      tarantula_rep << t_count
      other_rep << o_count
      max = [max, t_count, o_count].max
    end
    
    h1 @name
    show_params(['Project', project],
                ['Test Area', test_area],
                ['Weeks',  "#{weeks.first}-#{weeks.last}"])
    line_chart(nil, weeks.map{|w| "Week #{w}"},
               [{:values => tarantula_rep, 
                 :colour => '#FF0000',
                 :text   => 'Tarantula Testing'},
                {:values => other_rep, 
                 :colour => '#00FF00',
                 :text   => 'Other Sources'}], max, :vertical_labels)
    text "Results concern all test objects at the given week range."
  end
  
end

end # Module Report
