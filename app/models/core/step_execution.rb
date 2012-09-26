=begin rdoc

Execution of a single step (of a case).

=end
class StepExecution < ActiveRecord::Base
  extend CsvExchange::Model
  alias_attribute :name, :id
  belongs_to :step, :class_name => 'Step', :foreign_key => 'step_id'
  belongs_to :case_execution

  belongs_to :creator,
             :class_name => 'User',
             :foreign_key => 'created_by'

  belongs_to :bug

  def step=(s)
    self[:step_id] = s.id
    self[:step_version] = s.version
  end

  def versioned_step
    @versioned_step ||= begin
                          if step.version != self[:step_version]
                            step.revert_to(self[:step_version])
                          end
                          step
                        end
  end

  def to_data
    step = versioned_step
    the_bug = nil
    # Show bug only if bug_tracker set for project
    # and the linked bug is in the tracker
    bt = case_execution.test_case.project.bug_tracker
    the_bug = self.bug if bt and bt.bug_ids.include?(self.bug_id)
    {
      :id => self.id,
      :step_id => step.id,
      :order => self.position,
      :action => step.action,
      :stepresult => step.result,
      #Step (expected) result. Attribute name is changed to
      #because of conflict with step execution result.
      :history => step.history(self),
      :version => step.version,              #Is this needed?
      :result => self.result.ui,
      :comment => self.comment,
      :bug => the_bug ? the_bug.to_data : nil
    }
  end

  # takes a bug#to_data style hash
  def bug=(h)
    if h.blank?
      self.bug_id = nil
      return
    end
    h.symbolize_keys!
    self.bug_id = h[:id]
  end

  define_csv do
    attribute :id,              'Step Execution Id', :identifier => true
    field     :action,          'Action'
    field     :expected_result, 'Expected Result'
    attribute :passed,          'Passed'
    attribute :failed,          'Failed'
    attribute :skipped,         'Skipped'
    attribute :not_implemented, 'Not Implemented'
    attribute :not_run,         'Not Run'
    attribute :comment,         'Comment'
    after_update do |step_execution|
      step_execution.case_execution.update_result(nil, false)
    end
  end
  
  def passed; self.result == Passed ? 'X' : '' end
  def failed; self.result == Failed ? 'X' : '' end
  def skipped; self.result == Skipped ? 'X' : '' end
  def not_implemented; self.result == NotImplemented ? 'X' : '' end
  def not_run; self.result == NotRun ? 'X' : '' end

  def passed=(r); self.result = Passed unless r.blank? end
  def failed=(r); self.result = Failed unless r.blank? end
  def skipped=(r); self.result = Skipped unless r.blank? end
  def not_implemented=(r); self.result = NotImplemented unless r.blank? end
  def not_run=(r); self.result = NotRun unless r.blank? end

  def action
    self.step.action
  end

  def expected_result
    self.step.result
  end

  def result; ResultType.send(self['result']); end
  def result=(r); self['result'] = r.db; end
end
