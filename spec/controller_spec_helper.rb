require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

def log_in(opts = {:admin => true})
  u_klass = opts[:admin] ? Admin : User
  @user = u_klass.make!(:login => 'tester', :id => 1)
  @project = Project.make!
  @user.project_assignments.create!(:project => @project, 
                                    :group   => (opts[:group] || 'MANAGER'))
  controller.instance_variable_set(:@current_user, @user)
  controller.instance_variable_set(:@project, @project)
  
  flexmock(controller).should_receive(:set_current_user_and_project).and_return(true)
  flexmock(controller).should_receive(:require_permission).and_return(true)
end

