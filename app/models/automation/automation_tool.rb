class AutomationTool < ActiveRecord::Base
  attr_accessible :command_pattern, :name

	has_many :projects
  validates_presence_of :name, :command_pattern

  def to_tree
    {:id => self.id,
     :name => self.name }
  end
end
