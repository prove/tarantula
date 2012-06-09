=begin rdoc

Bug.

=end
class Bug < ActiveRecord::Base
  alias_attribute :name, :summary

  belongs_to :severity, :class_name => 'BugSeverity', :foreign_key => 'bug_severity_id'
  belongs_to :product, :class_name => 'BugProduct', :foreign_key => 'bug_product_id'
  belongs_to :component, :class_name => 'BugComponent', :foreign_key => 'bug_component_id'
  belongs_to :bug_tracker # not project
  belongs_to :creator, :foreign_key => 'created_by', :class_name => 'User'

  validates_presence_of :external_id, :bug_severity_id, :bug_tracker_id, :bug_product_id
  validates_uniqueness_of :external_id, :scope => :bug_tracker_id
  has_many :step_executions

  # default ordering
  scope :ordered, order('CAST(external_id AS UNSIGNED) DESC')
    
  # NOTE: Both :not_closed and :s_open needed because verified status is not considered
  # to be either one.
  scope :not_closed, lambda{|bt_type|
    c = CustomerConfig.find(:first, :conditions => {
                              :name => bt_type.downcase + '_closed_statuses'})
    if c
      conds = c.value
    else
      conds = BT_CONFIG[bt_type.downcase.to_sym][:closed_statuses]
    end
    {:conditions => "status NOT IN (#{conds.map{|t|"'%s'"%t}.join(',')})"}
  }
  scope :s_open, lambda{|bt_type|
    c = CustomerConfig.find(:first, :conditions => {
                              :name => bt_type.downcase + '_open_statuses'})
    if c
      conds = c.value
    else
      conds = BT_CONFIG[bt_type.downcase.to_sym][:open_statuses]
    end
    {:conditions => {:status => conds}}
  }

  # don't store the longdesc of bugzilla in db..
  attr_accessor :desc

  def deleted; false; end
  def self.external_id_scope; :bug_tracker; end
  # Return label for the bug.
  # In Bugzilla case this could be id summary
  # and in Jira case [issue-key
  def to_s; self.bug_tracker.bug_label(self); end

  def to_data
    {:id => self.id,
     :name => self.to_s,
     :external_id => self.external_id}
  end

  # return all bugs which are linked to step executions with given parameters
  # hash_by is a method or a sequence of methods to call, e.g. 'severity.name'
  def self.all_linked(project, test_objects=nil, test_area=nil,
                      hash_by=nil, extra_conds=nil)
    bugs = []
    conds = ["executions.project_id=:p_id and bug_id is not null",
             {:p_id => project.id}]
    if extra_conds
      conds[0] += (" and "+extra_conds[0])
      conds[1].merge!(extra_conds[1])
    end

    if test_objects
      test_objects = [test_objects].flatten
      conds[0] += " and executions.test_object_id in (:to_ids)"
      conds[1].merge!({:to_ids => test_objects.map(&:id)})
    end

    if test_area
      eids = test_area.executions.active.map(&:id)
      conds[0] += " and executions.id in (:eids)"
      conds[1].merge!({:eids => eids})
    end

    ses = StepExecution.find(:all, :joins => [:bug, {:case_execution => :execution}],
                             :conditions => conds)
    ses.each {|se| bugs << se.bug if se.bug }
    bugs.uniq!
    return bugs unless hash_by

    ret = ActiveSupport::OrderedHash.new
    bugs.each do |bug|
      key = bug.instance_eval(hash_by)
      ret[key] ||= []
      ret[key] << bug
    end
    ret
  end

  # get the result types of linked step_executions in the executions
  def linked_result_types(execution_ids)
    ses = self.step_executions.find(:all, :joins => {:case_execution => :execution},
      :conditions => ["executions.id IN (:eids)", {:eids => execution_ids}])
    h = {}
    ses.map{|se| se.result.rep}.each{|t| h[t] ||= 0; h[t] += 1}
    ret = []
    h.each{|k,v| v > 1 ? ret << "#{k}" : ret << k }
    ret.sort.join(' + ')
  end

  def link; self.bug_tracker.bug_show_url(self) end

end
