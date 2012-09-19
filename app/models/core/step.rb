=begin rdoc

Step of a case.

=end
class Step < ActiveRecord::Base
  extend CsvExchange::Model
  acts_as_versioned
  self.locking_column = :version

  has_and_belongs_to_many_versioned :cases, :include_join_fields => [:position]
  
  has_many :executions, :class_name => 'StepExecution',
           :foreign_key => 'step_id'
  
  validates_presence_of :action
  validates_presence_of :result
  
  # execution history, excluding step execution exclude_se
  def history(exclude_se = nil)
    return [] unless executions
    opts = {:limit => 3, :joins => {:case_execution => {:execution => :test_object}},
            :order => 'test_objects.created_at DESC, step_executions.id DESC'}
    conds = "step_executions.result != '#{NotRun}'"
    conds += " AND step_executions.id != #{exclude_se.id}" if exclude_se
    opts.merge!({:conditions => conds})
    
    self.executions.find(:all, opts).map do |e|
      {:result => e.result.ui, 
       :test_object => e.case_execution.execution.test_object.name,
       :comment => e.comment, 
       :bug => e.bug ? e.bug.to_data : nil}
    end
  end

  def to_data
    {
      :id => self.id,    #Actual step id, not versioned step id.
      :action => self.action,
      :result => self.result,
      :version => self.version,
      :position => self.position
    }
  end

  def update_if_needed(data)
    new_atts = data.symbolize_keys
    new_atts.delete(:id)
    new_atts.delete(:version) # not needed..
    if [self.position, self.action, self.result] !=
       [new_atts[:position], new_atts[:action], new_atts[:result]]
      self.update_attributes(new_atts) # increases version
    end
  end
  
  def to_s
    "#{self.position} Action: #{self.action} Result: #{self.result}"
  end

  define_csv do
    attribute :id,     'Step Id', :identifier => true
    attribute :action, 'Action'
    attribute :result, 'Result'
  end

end
