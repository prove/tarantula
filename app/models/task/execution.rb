module Task

=begin rdoc

A dummy task for not finished executions.

=end  
class Execution
  
  def initialize(execution, assignee, case_count=nil)
    @execution, @assignee, @case_count = execution, assignee, case_count
  end
  
  def project; @execution.project; end
  def resource; @execution; end
  def assignee; @assignee; end
  def creator; @assignee; end
  def finished?; false; end
  
  def to_data
    raise "#to_data not implemented!"
  end
  
  def as_json(opts=nil)
    self.to_data.as_json(opts)
  end
  
  def name; "Execution"; end
  
  def item_class; "Execution"; end
  def item_name; resource.name; end
  
  def description
    count = ''
    count = " (#{@case_count})" if @case_count
    "Not run cases assigned to you%s" % count
  end
  
  def link; 'execute'; end
end

end # module Task
