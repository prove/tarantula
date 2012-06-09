=begin rdoc

User's assignment to a project. Includes single access group.

=end
class ProjectAssignment < ActiveRecord::Base
  belongs_to :project
  belongs_to :user
  belongs_to :test_area
  belongs_to :test_object
  
  validates_presence_of :project_id, :user_id, :group
  validates_inclusion_of :group, :in => (User::Groups.values + ['ADMIN'])
  validate :one_assignment_per_user_per_project
  
  delegate :realname, :to => :user
  delegate :login, :to => :user
  
  scope :nonadmin, where(:group => User::Groups.values)
  
  def project_name
    return project.name
  end
  
  def to_data
    {:group => self.group,
     :login => self.user.login,
     :deleted => self.user.deleted,
     :test_area => self.test_area ? self.test_area.name : nil,
     :test_area_forced => self.test_area_forced,
     :test_object => self.test_object}
  end
  
  private
  
  def one_assignment_per_user_per_project
    return unless self.new_record?
    if project.assignments.count(:conditions => {:user_id => self.user_id}) >= 1
      raise "User already has an assignment for project \"#{project.name}\"!"
    end
  end
  
end
