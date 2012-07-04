module Report

=begin rdoc

Workload report.

=end
class Workload < Report::Base
  
  def initialize(project_id)
    super()
    @name = "Project Workload"
    @options = {:project_id => project_id}
  end
  
  # don't cache
  def expires_in; 0.minutes; end
  
  protected
  
  def do_query
    project = Project.find(@options[:project_id])
    
    cols = ActiveSupport::OrderedHash.new
    cols[:name] = 'Name'
    cols[:cases] = 'Cases'
    cols[:duration] = 'Duration'
    rows = []
    
    eids = project.executions.active.not_completed
    
    total_cases = 0
    total_duration = 0
    
    project.users.sort{|a,b| a.name <=> b.name}.each do |user|
      ces = CaseExecution.find(:all, :conditions => {:execution_id => eids,
                                                     :result       => NotRun.db,
                                                     :assigned_to  => user.id})
      cases = ces.size
      duration = Case.total_avg_duration(ces.map(&:case_id))
      
      unless ces.empty?
        rows << {:name     => user.name,
                 :cases    => cases,
                 :duration => duration.to_duration}
      end
      
      total_cases += cases
      total_duration += duration
    end
    
    ### Total assigned
    rows << {:name     => 'Total assigned',
             :cases    => total_cases,
             :duration => total_duration.to_duration}
    
    # Unassigned
    unassigned = CaseExecution.find(:all, :conditions => {:execution_id => eids,
                                                       :result => NotRun.db,
                                                       :assigned_to => nil})
    if unassigned.size > 0
      rows << {:name => 'Unassigned',
               :cases => unassigned.size,
               :duration => Case.total_avg_duration(unassigned.map(&:case_id)).to_duration}
    end
    
    h1 @name
    t cols, rows
  end
end


end # module Report
