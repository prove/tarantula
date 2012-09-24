require 'csv'

=begin rdoc

Execution. Reflects execution of a single test set.

=end
class Execution < ActiveRecord::Base
  include TaggingExtensions
  extend CsvExchange::Model
  scope :active, where(:deleted => 0, :archived => 0)
  scope :deleted, where(:deleted => 1)
  scope :completed, where(:completed => true)
  scope :not_completed, where(:completed => false)

  # default ordering
  scope :ordered, joins(:test_object).order('test_objects.date DESC')

  self.locking_column = :version

  belongs_to :test_object
  belongs_to :project
  has_and_belongs_to_many :test_areas
  belongs_to :creator, :class_name => 'User', :foreign_key => 'created_by'
  belongs_to :updater, :class_name => 'User', :foreign_key => 'updated_by'

  has_many :case_executions, :dependent => :destroy, :order => 'position'
  has_many :step_executions, :through => :case_executions,
           :order => 'position'

  validates_presence_of :name, :test_object_id, :project_id, :date

  # Return all who have been assigned to execute cases for this execution.
  def assigned_to
    ret = Array.new
    case_executions.each{ |ce|
      ret << ce.assignee
    }
    ret.uniq!
    ret.compact!
    return ret
  end

  def duration
    (case_executions.sum(:duration) || 0)
  end

  # Methods for reporting
  def number_of_cases
    return case_executions.count
  end

  def passed_cases
    case_executions.count(:conditions => "result = '#{Passed}'")
  end

  def failed_cases
    case_executions.count(:conditions => "result = '#{Failed}'")
  end

  def skipped_cases
    case_executions.count(:conditions => "result = '#{Skipped}'")
  end

  def unhandled_cases
    case_executions.count(:conditions => "result = '#{NotRun}'")
  end

  def cases_run
    case_executions.count(:conditions => "result != '#{NotRun}'")
  end

  # Handled cases / num of cases
  def test_coverage(numeric = false)
    if self.number_of_cases == 0
      return 0 if numeric
      return 'undefined'
    end
    tc = (100 * (self.cases_run.to_f / self.number_of_cases))
    return tc if numeric
    return "%i%%" % tc
  end

  # Passed cases / num of cases
  def raw_maturity(numeric = false)
    if self.number_of_cases == 0
      return 0 if numeric
      return 'undefined'
    end
    rm = (100 * (self.passed_cases.to_f / self.number_of_cases))
    return rm if numeric
    return "%.2f%%" % rm
  end

  # Passed cases / handled cases
  def tested_maturity(numeric = false)
    handled = self.passed_cases + self.failed_cases
    if (handled == 0)
      return 0 if numeric
      return "undefined"
    end
    tm = (100 * (self.passed_cases.to_f / handled))
    return tm if numeric
    return "%.2f%%" % tm
  end

  def avg_duration
    Case.total_avg_duration(self.case_executions.map(&:case_id))
  end

  # Estimated remaining duration
  def erd
    erd = 0.seconds
    self.case_executions.find(:all, :conditions => "result = '#{NotRun}'")\
      .each { |uh| erd += uh.test_case.avg_duration }
    erd
  end

  def erd_by_user(u)
    erd = 0.seconds
    self.case_executions.find(:all, :conditions => "result = '#{NotRun}' "+
      "AND assigned_to = #{u.id}").each { |uh| erd += uh.test_case.avg_duration }
    erd
  end

  def case_execution_by_case(c)
    case_executions.find_by_case_id(c.id)
  end

  def long_name
    "#{self.name} (#{self.test_object.name}) (#{self.test_coverage})"
  end

  def to_tree
    {
      :text => self.long_name,
      :leaf => true,
      :dbid => self.id,
      :deleted => self.deleted,
      :archived => self.archived,
      :cls => "x-listpanel-item",
      :tags => self.tags_to_s
    }
  end

  def to_data(*args)
    if args.include? :brief
      return {
        :name => self.long_name,
        :id => self.id,
        :date => self.date,
        :tag_list => self.tags_to_s,
        :test_area_ids => self.test_area_ids
      }
    end
    self.attributes.merge({:test_object => self.test_object.name,
                           :tag_list => self.tags_to_s,
                           :test_area_ids => self.test_area_ids,
                           :average_duration => self.avg_duration})
  end

  # This has to be optimized enough to function with thousand cases' sets
  def self.create_with_assignments!(atts, cases, creator_id, tag_list=nil)
    raise "Execution must have cases!" if cases.empty?
    cases = remove_duplicates(cases)

    e = nil
    transaction do
      # 1) create execution
      e = Execution.create!(atts)
      e.tag_with(tag_list) unless tag_list.blank?

      # 2) create all case executions
      ce_values = []

      cases.each{|x|
        ce_values << "(#{e.id}, #{x['id']}, #{(x['assigned_to'] || 'NULL')}, "+
                     "#{x['position']}, (select cases.version from cases where cases.id=#{x['id']}), "+
                     "(select cases.title from cases where cases.id=#{x['id']}), "+
                     "#{creator_id}, '#{NotRun}', NOW())"
      }
      connection.execute(
        "INSERT INTO case_executions (execution_id, case_id, assigned_to, "+
        "position, case_version, title, created_by, result, created_at) VALUES "+
        "#{ce_values.join(',')}")

      # 3) create all step executions
      connection.execute(
        "INSERT INTO step_executions (step_id, result, "+
        "step_version, position, case_execution_id) "+
        "SELECT cases_steps.step_id, '#{NotRun}', cases_steps.step_version, "+
        "cases_steps.position, case_executions.id FROM cases_steps JOIN cases ON "+
        "cases_steps.case_id=cases.id AND cases_steps.case_version="+
        "cases.version JOIN case_executions ON "+
        "case_executions.case_id=cases.id AND "+
        "case_executions.case_version=cases.version WHERE "+
        "case_executions.execution_id=#{e.id}")
    end
    e
  end

  def update_with_assignments!(atts, cases, tag_list=nil)
    raise "Execution must have cases!" if cases.blank?
    cases = self.class.remove_duplicates(cases)

    transaction do
      if atts['test_object'].respond_to?(:to_str)
        atts['test_object'] = self.project.test_objects.
          find_or_create_by_name(atts['test_object'])
      end

      self.update_attributes!(atts)

      new_ids = []
      cases.each do |x|
        ce = CaseExecution.find(:first, :conditions => {:case_id => x['id'],
                                  :execution_id => self.id})
        if ce
          ce.update_attributes!({
            :assigned_to => x['assigned_to'] ? x['assigned_to'].to_i : nil,
            :position => x['position']})
        else
          CaseExecution.create_with_steps!({:execution => self,
                                            :case_id => x['id'],
                                            :title => Case.find(x['id']).title,
                                            :assigned_to => x['assigned_to'],
                                            :position => x['position']})
        end
        new_ids << x['id']
      end

      # CaseExecution#destroy should be used to ensure that proper
      # callback are run. Ie. associated steps are deleted also.
      CaseExecution.all(:conditions => ["case_executions.execution_id = ? AND \
                                         NOT case_executions.case_id in (#{new_ids.join(',')})",
                                        self.id]
                        ).each do |ce|
        ce.destroy
      end

      self.tag_with((tag_list || ''))
    end
  end

  def reposition_case_executions
    self.case_executions.each_with_index do |ce,i|
      ce.update_attribute(:position, i+1)
    end
  end

  define_csv do
    attribute   :id,           'Execution Id', :identifier => true
    attribute   :name,         'Name'
    attribute   :date,         'Date'
    association :test_object,  'Test Object', :map => :name
    field       :avg_duration, 'Estimated Duration'
    attribute   :completed,    'Completed'
    association :test_areas,   'Test Areas', :map => :name
    association :tags,         'Tags', :map => :name
    children    :case_executions
  end

  private
  # TODO: refactor to some json input helper module
  def self.remove_duplicates(case_input)
    cases_in = []
    case_input.each_with_index do |c, i|
      unless cases_in.detect{|ci| ci['id'] == c['id']}
        c['position'] = cases_in.size+1
        cases_in << c
      end
    end
    cases_in
  end

end
