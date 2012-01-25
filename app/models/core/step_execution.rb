=begin rdoc

Execution of a single step (of a case).

=end
class StepExecution < ActiveRecord::Base
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

  def to_csv(delimiter=';', line_feed="\r\n")
    vals = ['']*5 + [self.id.to_s, self.step.action, self.step.result] +
      ResultType.all.map{|rt| self.result == rt ? 'X' : ''} +
      [(self.bug ? self.bug.to_s : ''), self.comment]

    vals.map{|v| v.blank? ? '': "\"#{v}\""}.join(delimiter)
  end

  def result; ResultType.send(self['result']); end
  def result=(r); self['result'] = r.db; end
end
