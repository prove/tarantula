=begin rdoc

A snapshot of a bug tracker.

=end
class BugTrackerSnapshot < ActiveRecord::Base
  belongs_to :bug_tracker
  has_many :bugs, :class_name => 'BugSnapshot', :dependent => :destroy
  before_create :take_bug_snapshots
  
  validates_presence_of :name
  
  private
  def take_bug_snapshots
    transaction do
      self.bug_tracker.bugs.each do |bug|
        self.bugs.build(:bug => bug, :bug_tracker_snapshot => self)
      end
    end
  end
end
