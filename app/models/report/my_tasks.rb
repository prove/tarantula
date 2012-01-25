module Report

=begin rdoc

Report not finished tasks of user.

=end
class MyTasks < Report::Base

  def initialize(user_id)
    super()
    @name = "My Tasks (All Projects)"
    @options = { :user_id => user_id }
  end

  protected

  def do_query
    user = User.find(@options[:user_id])
    tasks = user.tasks.unfinished
    tasks += user.execution_tasks

    columns = [[:project,     'Project'],
               [:target_item, 'Target Item'],
               [:target_name, ''],
               [:description, 'Description']]
    rows = []
    
    projects = tasks.map(&:project).uniq.sort{|a,b| a.name <=> b.name}
    
    projects.each do |proj|
      rows << {:project => proj.name}
      
      tasks.select{|t| t.project == proj}.each do |task|
        h = {:project => '',
             :project_id => task.project.id,
             :target_item => "#{task.item_class}",
             :target_name => "#{task.item_name}",
             :description => task.description }
        
        h.merge!(:links => Report::Ext.rep_link_for(
                 task.resource, :target_name, task.link)) if task.link
                 
        rows << h
      end
    end

    h1 @name
    t(columns, rows, :collapsable => true)
  end

end

end # module Report
