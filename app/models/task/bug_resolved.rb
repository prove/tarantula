module Task

=begin rdoc

Task for resolved bug.

=end
class BugResolved < Task::Base
  
  def name; "Bug Resolved" end
  
  def link; self.resource.try(:link) end
  
  def item_class; "Defect" end
  def item_name; resource ? resource.to_s : '[BUG REMOVED FROM PROJECT]' end
end

end # module Task