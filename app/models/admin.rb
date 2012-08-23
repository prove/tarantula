=begin rdoc

Admin specific user logic.

=end
class Admin < User # STI
  def admin?; true; end
  
  # just create all missing project assignments with group 'ADMIN'
  # N.B. doesn't change the behaviour of Project#assignments
  def project_assignments_with_admin
    missing = Project.all - self.projects
    
    missing.each do |m|
      ProjectAssignment.create!(:user_id => self.id, :project_id => m.id, 
                                :group => 'ADMIN')
    end
    self.clear_association_cache unless missing.empty?
    project_assignments_without_admin
  end
  alias_method_chain :project_assignments, :admin
  
  def allowed_in_project?(pid,req_groups = nil); true; end

  def remove_admin_assignments
    admin_assignments = ProjectAssignment.where(:user_id => self.id, 
                                                :group => 'ADMIN')
    admin_assignments.map(&:destroy)
  end
  
end
