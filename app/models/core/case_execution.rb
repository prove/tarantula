=begin rdoc

A case execution. Reflects execution of a case.

=end
class CaseExecution < ActiveRecord::Base
  extend CsvExchange::Model
  belongs_to :creator, :class_name => 'User', :foreign_key => 'created_by'
  belongs_to :test_case, :class_name => 'Case', :foreign_key => 'case_id'

  belongs_to :assignee, :class_name => 'User', :foreign_key => 'assigned_to'
  belongs_to :executor, :class_name => 'User', :foreign_key => 'executed_by'

  belongs_to :execution

  has_many :step_executions, :dependent => :destroy, :order => 'step_executions.position ASC'

  validates_presence_of :execution_id, :case_id
  validates_presence_of :executed_at, :executed_by, :duration, :if => \
    Proc.new {|ce| ![nil, NotRun].include?(ce.result)}

  validates_numericality_of :position, :only_integer => true,
                            :greater_than => 0, :on => :create

  delegate :objective, :test_data, :preconditions_and_assumptions, :to => :versioned_test_case
  delegate :avg_duration, :history, :to => :test_case

  def self.create_with_steps!(atts)
    ce = nil
    transaction do
      c = Case.find(atts[:case_id])
      atts.symbolize_keys!
      atts.merge!(:result => NotRun, :case_version => c.version)

      ce = CaseExecution.create!(atts)

      pos = 1
      c.steps.each{|s|
        se = StepExecution.create!(:step => s,
                                   :case_execution => ce,
                                   :result => NotRun,
                                   :step_version => s.version,
                                   :position => pos)
        pos += 1
      }
    end
    return ce
  end

  def update_with_steps!(atts, se_data, updater)
    transaction do
      se_data.each do |se|
        step_execution = self.step_executions.find(se['id'])

        step_execution.update_attributes!({
          :result => ResultType.send(se['result']),
          :bug => se['bug'],
          :comment => se['comment']
        })
      end

      self.update_attributes!(
        {:executed_at => Time.now,
         :executor => updater,
         :duration => atts["duration"]})

      self.update_result(updater)
    end
  end

  def step_exec_by_step(step)
    return step_executions.find_by_step_id(step.id)
  end

  def update_result(updater, recurse=true)
    results = step_executions.collect{|s|s.result}
    nr = ResultType.result_by_rank(results)
    transaction do
      self.update_attribute(:result,nr)
      self.update_duplicates(updater) if recurse and CustomerConfig.update_duplicates
    end
  end

  # Update duplicate executions of the same test case in the same
  # test object. User's current test area limits executions considered.
  def update_duplicates(updater)
    conds = ['case_id=:c_id and case_version=:c_ver and '+
             'executions.test_object_id=:to_id',
             {:c_id => self.case_id, :c_ver => self.case_version,
              :to_id => self.execution.test_object_id}]

    if ta = updater.test_area(self.execution.project)
      conds[0] += ' and exists (select * from executions_test_areas where '+
                  'execution_id=executions.id and test_area_id=:ta_id)'
      conds[1][:ta_id] = ta.id
    end

    dups = CaseExecution.find(:all, :include => [:step_executions, :execution],
                              :conditions => conds)
    dups.delete(self)

    return if dups.empty?

    transaction do
      self.step_executions.each_with_index do |se, i|
        dups.each do |ce_dup|
          ce_dup.step_executions[i].update_attributes!(:result  => se.result,
                                                       :bug_id  => se.bug_id,
                                                       :comment => se.comment)
        end
      end

      dups.each do |ce_dup|
        ce_dup.update_attributes!(:executed_at => self.executed_at,
                                  :executor => updater,
                                  :duration => self.duration)
        ce_dup.update_result(updater, false)
      end
    end
  end

  def test_case=(c)
    self[:case_id] = c.id
    self[:case_version] = c.version
    self[:title] = c.title
  end

  def versioned_test_case
    @versioned_test_case ||= begin
                               if test_case.version != self[:case_version]
                                 test_case.revert_to(self[:case_version])
                               end
                               test_case
                             end
  end

  def comments
    return step_executions.map{|se|
      se.comment
    }.join(' ').strip
  end

  def bugs_to_s
    self.step_executions.map{|se| se.bug ? se.bug.to_s : nil}.compact.join(', ')
  end

  def to_data(*opts)
    tc = self.test_case
    history = tc.history # history before revert (cache_key)
    tc = versioned_test_case

    data = {:id            => id,
            :case_id       => tc.id,
            :title         => title,
            :time_estimate => avg_duration,
            :duration      => duration,
            :assigned_to   => assigned_to,
            :result        => result.ui,
            :executed_by   => executed_by,
            :executed_at   => executed_at,
            :history       => history,
            :position      => position,
            :objective     => tc.objective,
            :test_data     => tc.test_data,
            :preconditions_and_assumptions => tc.preconditions_and_assumptions,
            :tags          => tc.tags_to_s}

    data.merge!(:steps => step_executions.map(&:to_data)) if opts.include?(:include_steps)
    data
  end

  def executed_by
    executor.try(:name)
  end

  def time_estimate
    avg_duration
  end

  def failed_steps_info
    failed = self.step_executions.find(:all, :conditions => {:result => Failed.to_s})
    return nil if failed.empty?
    info = "FAILED: "
    info += failed.map{|f| "step #{f.position}, #{f.step.action}"}.join('; ')
    info
  end

  def destroy_if_not_last
    transaction do
      lock!
      if self.execution.case_executions.count == 1
        raise "Can't remove last case from execution!"
      end
      destroy
    end
  end

  def update_case_version(ver, updater)
    transaction do
      update_attributes!({:case_version => ver})

      run = self.step_executions.find(:all, :conditions => "result != '#{NotRun}'").\
        map{|se| se.attributes.symbolize_keys.merge(:result => se.result)}

      self.step_executions.destroy_all

      versioned_test_case.steps.each do |s|
        atts = run.detect{|r| r[:step_id] == s.id}
        atts ||= {:result => NotRun}
        atts.merge!({:step_id => s.id, :step_version => s.version,
                     :position => s.position})
        self.step_executions.create!(atts)
      end

      self.update_result(updater, false)
    end
  end

  def result
    ResultType.send(self['result']) unless self['result'].nil?
  end
  def result=(r); self['result'] = r.db; end

  define_csv do
    attribute :id,                        'Case Execution Id', 
              :identifier => true
    field :title,                         'Case'
    field :objective,                     'Objective'
    field :test_data,                     'Test Data'
    field :preconditions_and_assumptions, 'Preconditions & Assumptions'
    children :step_executions
  end

end
