=begin rdoc

A snapshot of a bug.

=end
class BugSnapshot < ActiveRecord::Base
  belongs_to :bug_tracker_snapshot
  belongs_to :bug
  belongs_to :severity, :class_name => 'BugSeverity', :foreign_key => 'bug_severity_id'

  before_create :extract_data

  validates_presence_of :bug_id, :bug_tracker_snapshot_id

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

  delegate :link, :to => :bug
  delegate :to_s, :to => :bug

  private

  def extract_data
    atts = self.bug.attributes
    atts.delete('id')
    atts.delete('bug_tracker_id')
    self.attributes = atts
  end
end
