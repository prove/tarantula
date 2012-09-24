=begin rdoc

A test case.

=end
class Case < ActiveRecord::Base
  include AttachingExtensions
  include TaggingExtensions
  include ChangeHistory
  include PriorityExtensions
  extend CsvExchange::Model

  alias_attribute :name, :title

  scope :active, where(:deleted => 0, :archived => 0)
  scope :deleted, where(:deleted => 1)

  # default ordering
  scope :ordered, order('priority DESC, title ASC')

  acts_as_versioned
  self.locking_column = :version

  belongs_to :project
  has_and_belongs_to_many :test_areas
  belongs_to :creator, :class_name => 'User', :foreign_key => 'created_by'
  belongs_to :updater, :class_name => 'User', :foreign_key => 'updated_by'

  has_and_belongs_to_many_versioned :test_sets
  has_and_belongs_to_many_versioned :steps, :include_join_fields => [:position],
                                    :order => "COALESCE(jt.position, 0) ASC"
  has_and_belongs_to_many_versioned :requirements

  has_many :case_executions, :class_name => 'CaseExecution',
           :foreign_key => 'case_id', :dependent => :destroy

  has_many :step_executions, :through => :case_executions

  has_many :tasks, :class_name => 'Task::Base', :as => :resource,
           :dependent => :destroy

  validates_presence_of :title, :project_id, :date
  validates_uniqueness_of :external_id, :scope => :project_id, :allow_nil => true

  after_create :copy_attachments_from_original

  def copy_attachments_from_original
    if self.original_id
      orig = Case.find(self.original_id)
      orig.attachments.each do |att|
        self.attach(att)
      end
    end
  end

  ### Class methods begin ###

  def self.create_with_dummy_step(atts)
    a_case = nil
    transaction do
      a_case = self.create!(atts)
      a_case.steps << Step.create!(:action => '-', :result => '-',
                                   :position => 1)
    end
    a_case
  end

  def self.total_avg_duration(case_ids, strict=false)
    return 0 if case_ids.empty?
    sum_avg = 0
    sum_est = 0

    cids_by_freq = case_ids.by_frequency

    # all with freq 1, freq 2, freq 3 ...
    cids_by_freq.each do |freq, cids|
      avg = ActiveRecord::Base.connection.select_values(
        "SELECT #{freq}*SUM(avg_duration) as sum_avg FROM case_avg_duration WHERE "+
        "case_avg_duration.case_id IN (#{cids.map(&:to_s).join(',')}) AND "+
        "avg_duration > 0").first.to_i
      sum_avg += avg
    end

    return sum_avg if strict

    cids_by_freq.each do |freq, cids|
      est = ActiveRecord::Base.connection.select_values(
        "SELECT #{freq}*SUM(time_estimate)*60 as sum_est FROM cases WHERE "+
        "cases.id IN (#{case_ids.map(&:to_s).join(',')}) AND NOT EXISTS "+
        "(SELECT * FROM case_avg_duration WHERE case_avg_duration.case_id=cases.id "+
        "AND case_avg_duration.avg_duration > 0)").first.to_i
      sum_est += est
    end

    sum_avg + sum_est
  end

  # cumulative case-based results, i.e. results persist from earlier
  # test objects
  # returns nil for case which has no results (or only not runs)
  def self.cumulative_results(cases, test_object_ids, test_area=nil)
    return [] if test_object_ids.empty?
    cases = (test_area.cases.active.find(:all, :select => 'id,updated_at') & cases) if test_area
    cases.map{|c| c.last_results(test_object_ids, test_area).first}
  end

  def self.step_count(case_ids)
    return 0 if case_ids.empty?

    connection.select_value("select count(*) as count from steps join cases_steps on "+
      "steps.id=cases_steps.step_id and steps.version=cases_steps.step_version join "+
      "cases on cases_steps.case_id=cases.id and cases_steps.case_version=cases.version "+
      "where cases.id IN (#{case_ids.map(&:to_s).join(',')})").to_i
  end

  def self.create_with_steps!(atts, step_data, tag_list=nil)
    c = nil
    transaction do
      ce_id = atts.delete(:case_execution_id)
      eid = atts.delete(:execution_id)

      c = Case.create!(atts)
      c.steps << step_data.map{ |s| Step.new(s) }
      c.tag_with(tag_list) if tag_list

      # Agile: create case and case exec on the fly
      if eid
        exec = Execution.find(eid)
        pos = (ce_id ? CaseExecution.find(ce_id).position + 1 : 1)

        exec.case_executions.each do |other_ce|
          next if other_ce.position < pos
          other_ce.update_attributes!(:position => other_ce.position + 1)
        end
        CaseExecution.create_with_steps!(:case_id => c.id,
                                         :execution_id => exec.id,
                                         :position => pos)
      end
    end
    c
  end

  # Copy many cases from project/test_area to project/test_areas.
  # Takes project_id and opts hash, which uses keys:
  # * :case_ids
  # * :tag_ids
  # * :from_test_area
  # * :to_test_areas
  # * :user
  # * :from_project
  def self.copy_many_to(project_id, opts)
    proj = Project.find(project_id)

    if opts[:tag_ids]
      smart_tags, tag_ids = SmartTag.digest(opts[:tag_ids])
      tags = Tag.find(:all, :conditions => {:id => tag_ids})

      cases = Case.find_with_tags(tags, {:smart_tags => smart_tags,
                                         :test_area  => opts[:from_test_area],
                                         :project    => opts[:from_project]})
    else
      case_ids = opts[:case_ids].split(',')

      if ta = opts[:from_test_area]
        cases = ta.cases.find(:all, :conditions => {:id => case_ids})
      else
        cases = opts[:from_project].cases.find(:all,
                                               :conditions => {:id => case_ids})
      end
    end

    ta_ids = nil
    ta_ids = opts[:to_test_areas].split(',') unless opts[:to_test_areas].blank?

    transaction do
      cases.each do |c|
        c.copy_to(proj, opts[:user], ta_ids)
      end
    end
  end

  ### Class methods end ###

  def linked_to_req_ids
    connection.select_values("select distinct requirement_id from
        cases_requirements join requirements on
        cases_requirements.requirement_id=requirements.id where case_id='#{self.id}'
        and requirement_version=requirements.version")
  end

  # return linked requirements and test sets
  # include only links which have this case associated in their current version
  def linked_to
    @linked_to ||= begin
      ts_ids = connection.select_values("select distinct test_set_id from
        cases_test_sets join test_sets on cases_test_sets.test_set_id=test_sets.id
        where case_id='#{self.id}' and test_set_version=test_sets.version")

      Requirement.find(self.linked_to_req_ids) + TestSet.find(ts_ids)
    end
  end

  def linked_to_requirements
    @linked_to_requirements ||= begin
      Requirement.find(self.linked_to_req_ids)
    end
  end

  # Set related requirements
  # Requirements cannot be assigned directly to case (due versioning or smth.)
  # Instead, update each affected requirement separately to add/remove current case
  def update_requirements(requirements)

    new_req_ids = requirements.map{ |r| r.id}
    curr_req_ids = self.linked_to_requirements.map{ |r| r.id}

    # Requirements to be added to this case
    add_req_ids = new_req_ids - curr_req_ids
    # To be removed
    remove_req_ids = curr_req_ids - new_req_ids

    add_req_ids.each{ |r| Requirement.find(r).add_case(self.id) }
    remove_req_ids.each{ |r| Requirement.find(r).remove_case(self.id)}
  end

  def linked_to_str
    self.linked_to.map{|l| "#{l.class.to_s.titleize} \"#{l.name}\""}.join(', ')
  end

  def raise_if_delete_needs_confirm(multi)
    return if self.deleted?

    if !self.linked_to.empty?
      if multi
        msg = "Cases you delete will have their associations cleared. Are you sure?"
      else
        msg = "Are you sure you want to delete case \"#{self.name}\" ? It will "+
              "no longer be associated with: #{self.linked_to_str}."
      end
      raise ConfirmationNeeded.new(msg)
    end
  end

  def toggle_deleted
    transaction do
      if !self.deleted and !self.linked_to.empty?

        self.linked_to.each do |link|
          cases = link.cases
          cases.delete_if{|c| c.id == self.id}
          link.save! # make a new version

          cases.each_with_index {|c,i| c.position = i+1}
          link.cases << cases
        end

        self.change_comment = "Deleted. Following associations cleared: #{self.linked_to_str}"
        self.deleted = true
        self.archived = false
        old_step_ids = self.steps.map(&:id)
        self.save! # clears the associations to linked reqs & test sets
        old_steps = Step.find(old_step_ids)
        old_steps.each_with_index{|s,i| s.position = i}
        self.steps << old_steps
      else
        self.deleted = !deleted
        self.archived = false
        save_without_revision!
      end
    end
  end

  def avg_duration(strict=false)
    Rails.cache.fetch("#{self.cache_key}/avg_duration/strict=#{strict}") do
      Case.total_avg_duration([self.id], strict)
    end
  end

  def median_duration
    all = []
    case_executions.each{|e|
      all << e.duration
    }
    return (all.sort)[all.size / 2]
  end

  # define dynamically count methods for different result types,
  # e.g. passed_count.
  ResultType.all.each do |rt|
    rt_down = rt.to_s.downcase
    define_method((rt_down+"_count").to_sym) {
      case_executions.count(:conditions => "result = '#{rt}'")
    }
  end

  def result_by_execution(e)
    ce = case_executions.find_by_execution_id(e.id)
    return (ce ? ce.result : nil)
  end

  def to_tree
    {
      :text => self.title,
      :leaf => true,
      :dbid => self.id,
      :deleted => self.deleted,
      :archived => self.archived,
      :cls => "x-listpanel-item priority_#{self.priority}",
      :tags => self.tags_to_s,
      :version => self.version,
      :tasks => self.tasks
    }
  end

  def to_data(*opts)
    if (opts.include?(:brief)) # for new execution
      return { :position => self.position,
               :id => self.id,
               :date => self.date,
               :version => self.version,
               :title => self.title,
               :priority => self.priority_name,
               :test_area_ids => self.test_area_ids,
               :time_estimate => self.time_estimate ? \
                  self.time_estimate*60 : nil,
               :objective => self.objective,
               :test_data => self.test_data,
               :preconditions_and_assumptions => self.preconditions_and_assumptions }
    end

    ret = {
      :id => self.id,
      :date => self.date,
      :project_id => self.project_id,
      :title => self.title,
      :deleted => self.deleted,
      :archived => self.archived,
      :time_estimate => self.time_estimate,
      :created_by => self.creator.login,
      :created_at => self.created_at.strftime("%Y-%m-%d %H:%M:%S"),
      :updated_at => self.updated_at.strftime("%Y-%m-%d %H:%M:%S"),
      :updated_by => self.updater.login,
      :objective => self.objective,
      :test_data => self.test_data,
      :preconditions_and_assumptions => self.preconditions_and_assumptions,
      :version => self.version,
      :tasks => self.tasks,
      :priority => self.priority_name,
      :test_area_ids => self.test_area_ids,
      :average_duration => self.avg_duration(
                             opts.include?(:strict_average_duration))
    }

    if opts.include? :include_tag_list
      ret[:tag_list] = self.tags_to_s
    end
    ret
  end

  def copy_to(target_project, user, test_area_ids=nil)
    # Don't allow copying if target test area doesn't belong to target project
    if !test_area_ids.blank? and
        (target_project.test_area_ids & test_area_ids.map(&:to_i)).empty?
      return nil
    end

    atts = self.attributes.delete_if{|k,v|
      %w(id date created_at created_by updated_at updated_by change_comment\
         external_id deleted archived).include?(k)
    }.merge({:original_id => self.id,
             :date => Date.today,
             :project => target_project,
             :creator => user,
             :updater => user,
             :change_comment =>
             "Copied from project #{self.project.name} case #{self.title}",
             :test_area_ids => test_area_ids || []})
    atts['title'] = atts['title']+" (Copy)" if self.project == target_project

    copied = nil

    transaction do
      copied = Case.create!(atts)
      copied.tag_with(self.tags_to_s)

      self.steps.each_with_index do |s,i|
        copied.steps << Step.new(:action => s.action, :result => s.result,
                                 :position => i+1)
      end

      if self.project.library
        self.tag_with((target_project.name+","+self.tags_to_s).chomp)
      end
    end

    copied
  end

  # history of case_executions
  def history
    Rails.cache.fetch("#{self.cache_key}/history") do
      return [] if self.case_executions.count == 0

      opts = {:limit => 4,
              :order => 'test_objects.date DESC, case_executions.id DESC',
              :conditions => "case_executions.result != '#{NotRun}' AND "+
                             "executions.deleted=0",
              :joins => {:execution => :test_object}}

      self.case_executions.find(:all, opts).map do |ce|
        {:id               => ce.id,
         :result           => ce.result.ui,
         :execution_name   => ce.execution.name,
         :test_object_name => ce.execution.test_object.name}
      end
    end
  end

  def update_with_steps!(atts, step_data, tag_list=nil, ce=nil)
    transaction do
      self.update_attributes!(atts)
      step_data.map do |s|
        if s_id = s.delete('id')
          step = self.steps.detect { |cs| cs.id == s_id }
          step = Step.find(s_id) unless step
          step.update_if_needed(s)
        else
          step = Step.create(s)
        end
        self.steps << step
      end
      self.tag_with((tag_list || ''))

      if ce
        ce = self.case_executions.find(ce)
        ce.update_case_version(self.version, User.find(atts[:updated_by]))
        ce.update_attributes!({:title => self.title})
      end
    end
  end

  # returns test object that this case was last passed in
  def last_passed
    ce = self.case_executions.find(
      :first, :conditions => {:result => Passed.to_s,
                              'executions.deleted' => false},
      :order => 'executed_at desc', :joins => :execution,
      :include => {:execution => :test_object})
    ce ? ce.execution.test_object : nil
  end

  # returns test object that this case was last tested in
  def last_tested
    ce = self.case_executions.find(
      :first, :conditions => {:result => (ResultType.all - [NotRun]).map(&:db),
                              'executions.deleted' => false},
      :order => 'executed_at desc', :joins => :execution,
      :include => {:execution => :test_object})
    ce ? ce.execution.test_object : nil
  end

  # returns result of last case execution or NotRun
  def last_result
    ce = self.case_executions.find(:first, :order => 'executed_at desc',
         :joins => :execution, :conditions => {'executions.deleted' => false})
    ce ? ce.result : NotRun
  end

  # returns _execution_ this case last failed in
  def last_failed_exec
    ce = self.case_executions.first(:conditions => ["result = :res and executions.deleted = :f", {:res => Failed.db,:f => false}], :order => 'case_executions.executed_at desc', :include => :execution)
    ce ? ce.execution : nil
  end

  # returns results of this case in the last test object it was run in
  # N.B. Changed to not include NOT_RUN or SKIPPED !
  # N.B.2 test_object_ids must be ordered desc by date to get real results!!
  def last_results(test_object_ids, test_area=nil)
    hash_part = Digest::MD5.hexdigest("#{test_object_ids.map(&:to_s).join(',')}/#{test_area.try(:id)}")
    key = "#{self.cache_key}/last_results/#{hash_part}"

    res_vals = Rails.cache.fetch(key) do
      res = []
      if test_area
        eids = test_area.executions.active.find(:all, :select => :id,
          :conditions => {:test_object_id => test_object_ids})
      else
        eids = Execution.active.find(:all, :select => :id,
          :conditions => {:test_object_id => test_object_ids})
      end
      test_object_ids.each do |to_id|
        res = CaseExecution.where(
                         ["case_id=:case_id AND "+
                          "test_objects.id=:to_id AND "+
                          "executions.id IN (:eids) AND "+
                          "result not in (:not_counted)",
                          {:case_id => self.id,
                           :to_id => to_id,
                           :eids => eids,
                           :not_counted => [NotRun.db, Skipped.db]}]).
          joins(:execution => :test_object).
          select(:result).
          order('case_executions.executed_at desc')
        break unless res.empty?
      end
      res.map{|r| r.result.db}
    end

    # store in string values (cache) but return in ResultType
    res_vals.map{|r| ResultType.send(r)}
  end

  # IDs of bugs linked to this case. test_area limits executions considered.
  def linked_bug_ids(test_area=nil)
    Rails.cache.fetch("#{self.cache_key}/linked_bug_ids/#{test_area.try(:id)}") do
      eids = (test_area || self.project).executions.active.find(:all, :select => 'id').map(&:id)
      case_execs = self.case_executions.find(
        :all, :include => :step_executions, :joins => :execution,
        :conditions => ['executions.id in (:eids)', {:eids => eids}])

      case_execs.map do |ce|
        ce.step_executions.map{|se| se.bug ? se.bug.id : nil}
      end.flatten.compact.uniq
    end
  end

  define_csv do
    attribute   :id,            'Case Id', :identifier => true
    attribute   :title,         'Title'
    attribute   :date,          'Date'
    attribute   :priority,      'Priority', :map => :to_i
    attribute   :time_estimate, 'Planned duration (minutes)'
    association :test_areas,    'Test Areas', :map => :name
    field       :avg_duration,  'Average Duration'
    association :tags,          'Tags', :map => :name
    attribute   :objective,     'Objective'
    attribute   :test_data,     'Test Data'
    attribute   :preconditions_and_assumptions, 'Preconditions & Assumptions'
    children    :steps
  end
  
end
