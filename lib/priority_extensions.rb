=begin rdoc

Include this in a model which is to be prioritized.

=end
module PriorityExtensions
  
  def priority_name
    Project::Priorities.detect{|p| p[:value] == self.priority}[:name]
  end
  
  def priority=(p)
    if p.is_a? String
      p_val = Project::Priorities.detect{|pp| pp[:name] == p.downcase}
      if p_val
        self[:priority] = p_val[:value]
      else
        raise "Invalid priority '#{p}' for #{self.class} (id #{self.id})"
      end
    else
      self[:priority] = p
    end
  end
  
  def self.included(model)
    model.validates_inclusion_of :priority, :in => Project::Priorities.map{|p| p[:value]}
  end
  
end
