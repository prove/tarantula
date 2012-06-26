
module Task

=begin rdoc

Task base class.

=end
class Base < ActiveRecord::Base
  self.table_name = 'tasks'
  validates_presence_of :resource_id, :resource_type, :project_id, 
                        :created_by, :assigned_to
  belongs_to :project
  belongs_to :resource, :polymorphic => true
  belongs_to :assignee, :foreign_key => 'assigned_to', :class_name => 'User'
  belongs_to :creator, :foreign_key => 'created_by', :class_name => 'User'
  
  scope :unfinished, where(:finished => false)
  scope :finished, where(:finished => true)
  scope :ordered, order('updated_at desc')
  scope :active, where(["finished=0 or (finished=1 and updated_at > :time)", 
                       {:time => 2.weeks.ago}])
  
  def to_data
    {:id => self.id,
     :project_id => self.project_id,
     :name => self.name,
     :finished => self.finished,
     :finished_at => self.finished ? self.updated_at : nil,
     :description => self.description,
     :resource_type => self.resource_type,
     :resource_id => self.resource_id,
     :link => self.link,
     
     :assigned_to => self.assigned_to,
     :assignee => self.assignee ? self.assignee.name : nil,
          
     :created_by => self.created_by,
     :creator => self.creator ? self.creator.name : nil }
  end
  
  def item_class; resource.class.to_s; end
  def item_name; resource.name; end
  
  def as_json(opts=nil)
    self.to_data.as_json(opts)
  end
  
  # redefine in subclasses
  def name; "Task"; end
  
  # UI link
  def link
    return nil if resource.class == Project
    Report::Ext.ui_link_for(self.resource)
  end
end

end # module Task
