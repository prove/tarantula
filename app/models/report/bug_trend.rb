
module Report

=begin rdoc

Report: bug trend

=end
class BugTrend < Report::Base

  def initialize(project_id, test_area_id=nil, mode=nil)
    super()
    @name = "Defect Analysis"
    @options = {:project_id => project_id,
                :test_area_id => test_area_id,
                :mode => mode}
  end

  protected

  def do_query
    h1 @options[:mode] == :brief ? "Open Defects" : @name
    project = Project.find(@options[:project_id])
    return if fatal(project.bug_tracker.nil?, "No defect tracker.")
    bt = project.bug_tracker
    ta = TestArea.find_by_id(@options[:test_area_id])

    show_params(['Project', project], ['Test Area', ta])
    open_defects(project, ta, @options[:mode])

    return if @options[:mode] == :brief

    page_break
    open_defects_trend(project, ta)

    return if @options[:mode] == :status

    page_break
    weekly_defect_status(project, ta)
  end

  def open_defects(project, test_area, mode)
    bt = project.bug_tracker
    bt_type = bt[:type].downcase
    sevs = bt.severities.ordered.map(&:name)
    bug_hash = bt.bugs_by('severity.name', project, test_area)

    max = 0
    elems = sevs.map do |s|
      val = bug_hash[s] ? bug_hash[s].size : 0
      max = val if val > max
      {:values => [val],
       :type => 'bar',
       :text => s,
       'font-size' => 10,
       :tip => "\#val\# #{s}",
       :colour => BugSeverity.color(s, bt_type)}
    end

    if mode == :brief
      bar_chart(nil, ["Severity"], elems, max)
      return
    end

    h2 "Open Defects"
    conf = CustomerConfig.find(:first, :conditions => {:name => "%s_open_statuses" % bt_type})
    if conf
      statuses = conf.value
    else
      statuses = BT_CONFIG[bt_type.to_sym][:open_statuses]
    end
    text "(defects with status #{statuses.to_sentence(:words_connector => 'or ')})"
    bar_chart(nil, ["Severity"], elems, max)
    return if mode == :status

    bug_table(bug_hash, 'Severity', sevs) unless bug_hash.empty?
  end

  def open_defects_trend(project, test_area)
    bt = project.bug_tracker
    bt_type = bt[:type].downcase
    sevs = bt.severities.ordered.map(&:name)

    labels = []
    vals = []
    max = 0

    4.downto(0) do |offset|
      name, bugs = bt.bugs_by('severity.name', project, test_area, :s_open, offset, true)
      next if bugs.blank?
      labels << (name || 'unknown')
      new_max = bugs.values.map(&:size).sum
      max = new_max if new_max > max

      val_arr = []
      sevs.each do |sev|
        val_arr << {:val => bugs[sev].try(:size), :tip => "\#val\# #{sev}"}
      end
      vals << val_arr
    end

    conf = CustomerConfig.find(:first, :conditions => {:name => "%s_open_statuses" % bt_type})
    if conf
      statuses = conf.value
    else
      statuses = BT_CONFIG[bt_type.to_sym][:open_statuses]
    end

    h2 "Open Defects Trend"
    text "(defects with status #{statuses.to_sentence(:words_connector => 'or ')})"
    bar_stack_chart(nil, labels,
      [{:values => vals,
        :colours => sevs.map{|s| BugSeverity.color(s, bt_type)},
        :keys => sevs.map{|s| {:colour => BugSeverity.color(s, bt_type), :text => s, 'font-size' => 10}}
        }],
      max, :diagonal_labels)
  end

  # Weekly defect status with following classification.
  # :open:     new, assigned, reopened
  # :fixed:    resolved
  # :verified: verified
  # (bug statuses unconfirmed and closed are not reported)
  def weekly_defect_status(project, test_area)
    bt = project.bug_tracker
    bt_type = bt[:type].downcase

    labels = []
    vals = []
    statuses = {}
    max = 0
    cur_hash = nil

    # Get configuration how to group Bug Tracker app (Bugzilla, Jira
    # etc) specific statuses
    ['Open', 'Fixed', 'Verified'].each do |t|
        c = CustomerConfig.find(:first, :conditions => {
                                  :name => "%s_%s_statuses" % [bt_type, t.downcase]
                                })
        if c
          statuses[t] = c.value
        else
          statuses[t] = BT_CONFIG[bt_type.to_sym][("%s_statuses" % t.downcase).to_sym]
        end
    end

    4.downto(0) do |offset|
      name, bugs = bt.bugs_by('status', project, test_area, :all, offset, true)
      next if bugs.blank?

      # Group statuses according to the configuration retrieved earlier
      bug_hash = ActiveSupport::OrderedHash.new
      ['Open', 'Fixed', 'Verified'].each do |t|
        bug_hash[t] = []
        statuses[t].each do |s|
          bug_hash[t] += (bugs[s] || [])
        end
      end

      labels << (name || 'unknown')
      o_size = bug_hash['Open'].size
      f_size = bug_hash['Fixed'].size
      v_size = bug_hash['Verified'].size
      new_max = [o_size, f_size, v_size].sum
      max = new_max if new_max > max

      vals << [{:val => o_size, :tip => '#val# Open'},
               {:val => f_size, :tip => '#val# Fixed'},
               {:val => v_size, :tip => '#val# Verified'}]
      cur_hash = bug_hash if offset == 0
    end

    h2 "Weekly Defect Status"
    bar_stack_chart(nil, labels,
      [{:values => vals,
        :colours => ['#FF0000', '#BBCC00', '#00FF00'],
        :keys => [{:colour => '#FF0000', :text => 'Open',     'font-size' => 10},
                  {:colour => '#BBCC00', :text => 'Fixed',    'font-size' => 10},
                  {:colour => '#00FF00', :text => 'Verified', 'font-size' => 10}]}],
      max, :diagonal_labels)
    text "Open = #{statuses['Open'].to_sentence}. " +
      "Fixed = #{statuses['Fixed'].to_sentence}. " +
      "Verified = #{statuses['Verified'].to_sentence}"
    return if cur_hash.nil?
    h3 'Current'
    bug_table(cur_hash, 'Status', ['Open', 'Fixed', 'Verified'])
  end

  def bug_table(bug_hash, grouped_by, keys)
    cols = ActiveSupport::OrderedHash.new
    cols[:group] = grouped_by
    cols[:name] = 'Defect'
    rows = []

    keys.each do |key|
      if key_b = bug_hash[key]
        rows << {:group => key, :name => ''}
        key_b.each do |b|
          rows << {:group => '', :name => b.to_s,
                   :links => {:name => {:target => b.link}}}
        end
      end
    end
    t(cols, rows, :collapsable => true)
  end

end

end # Module Report
