module Report

=begin rdoc

Test result status.

=end
class TestResultStatus < Report::Base

  # N.B. one test object only
  def initialize(project_id,
                 test_area_id,
                 test_object_id)
    super()
    @name = "Test Result Status"
    @options = { :project_id => project_id,
                 :test_area_id => test_area_id,
                 :test_object_id => test_object_id }
  end

  protected

  def do_query
    proj = Project.find(@options[:project_id])
    to = TestObject.find(@options[:test_object_id])
    ta = TestArea.find_by_id(@options[:test_area_id])

    execs = to.executions
    execs &= ta.executions if ta

    h1 @name
    show_params(['Project', proj],
                ['Test Area',  ta],
                ['Test Object', to])
    h2 "Summary"
    summary_table(proj, execs)
    bug_table(proj, execs)
    test_sets(proj, execs)
    defects_found(proj, execs)
  end

  def test_sets(proj, execs)
    # reversely get test sets from executions
    case_ids = execs.map{|e| e.case_executions.map(&:case_id)}.flatten
    test_sets = proj.test_sets.select{|ts| !(ts.case_ids & case_ids).empty? }

    test_sets.each do |ts|
      h2 "Test set: #{ts.name}"
      conds = ["case_executions.case_id in (:cids)", {:cids => ts.case_ids}]
      h3 "Summary"
      summary_table(proj, execs, conds)
      bug_table(proj, execs, conds, :h3)
    end
  end

  def defects_found(proj, execs)
    cols = ActiveSupport::OrderedHash.new
    cols[:severity] = 'Severity'
    cols[:total] = 'Total'
    cols[:priority] = 'Priority'
    cols[:defect] = 'Defect'
    rows = []
    bugs = Bug.all_linked(proj, nil, nil, 'severity.name',
      ["case_executions.execution_id in (:eids)", {:eids => execs.map(&:id)}])

    bugs.sort{|a,b| b.to_s <=> a.to_s}.each do |sev, sev_bugs|
      rows << {:severity => sev, :total => sev_bugs.size}
      sev_bugs.each do |b|
        rows << {:priority => b.priority, :defect => b.to_s,
                 :links => {:defect => {:target => b.link}}}
      end
    end

    page_break
    h2 "Defects Found"
    unless rows.empty?
      t(cols, rows, :collapsable => true)
    else
      text "None."
    end
  end

  def summary_table(proj, execs, xtra_conds=nil)
    conds = ["executions.id in (:eids)", {:eids => execs.map(&:id)}]
    if xtra_conds
      conds[0] += " and #{xtra_conds[0]}"
      conds[1].merge!(xtra_conds[1])
    end

    rep = Report::Results.new(proj, conds, true)
    rep.query
    results = rep.tables.first.data

    cols = ActiveSupport::OrderedHash.new
    cols[:name] = ''
    ResultType.all.each{|rt| cols[rt.rep] = rt.rep}
    cols['Total'] = 'Total'

    failed = results.detect{|r| r[:name] == Failed.rep}[:test_results]
    passed = results.detect{|r| r[:name] == Passed.rep}[:test_results]
    tp_tot = passed + failed

    c_row = {:name => 'Count'}
    rp_row = {:name => 'Raw Pass Rate'}
    tp_row = {:name => 'Tested Pass Rate',
              'Passed' => "#{tp_tot != 0 ? passed.in_percentage_to(tp_tot) : ''}%",
              'Failed' => "#{tp_tot != 0 ? failed.in_percentage_to(tp_tot) : ''}%"}

    (ResultType.all.map(&:rep) + ['Total']).each do |t|
      r = results.detect{|r| r[:name] == t}
      c_row[t] = r[:test_results]
      rp_row[t] = r[:perc]
    end
    t(cols, [c_row, rp_row, tp_row])
  end

  def bug_table(proj, execs, xtra_conds=nil, h_cmd=:h2)
    cols = ActiveSupport::OrderedHash.new
    cols[:result] ='Result'
    cols[:case] = 'Case'
    cols[:defect] = 'Defect'
    cols[:comment] = 'Comment'
    cols[:severity] = 'Severity'
    cols[:priority] = 'Priority'

    eids = execs.map(&:id)
    conds = ["case_executions.execution_id in (:eids)", {:eids => eids}]
    if xtra_conds
      conds[0] += " and #{xtra_conds[0]}"
      conds[1].merge!(xtra_conds[1])
    end
    rows = []

    bug_hash = Bug.all_linked(proj, nil, nil,
      "linked_result_types(#{eids.inspect})", conds)

    # Add count of cases to hash keys (title)
    keys = bug_hash.keys
    keys.each{ |k|
      bug_hash[ k + " (" + bug_hash[k].length.to_s + ")" ] = bug_hash.delete(k)
    }

    bug_hash.keys.each do |res_type|
      rows << {:result => res_type}
      rt_bugs = bug_hash[res_type].sort{|a,b| a.severity <=> b.severity}
      rt_bugs.each do |b|
        b.step_executions.find(:all, :joins => {:case_execution => :execution},
          :conditions => ['executions.id in (:eids)', {:eids => eids}]).each do |se|
          rows << {:case     => se.case_execution.test_case.name,
                   :defect   => b.to_s,
                   :comment  => se.comment,
                   :severity => b.severity.name,
                   :priority => b.priority,
                   :links => {:defect => {:target => b.link}}}
        end
      end
    end
    unless rows.empty?
      send(h_cmd, "Defects")
      t(cols, rows, {:collapsable => true,
        :column_widths => {0 => 100, 1 => 290, 2 => 100, 3 => 100, 4 => 100, 5 => 70}})
    end
  end

end

end # module Report
