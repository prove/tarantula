class AutomationTool < ActiveRecord::Base
  attr_accessible :command_pattern, :name, :automation_tag

	has_many :projects
  validates_presence_of :name, :command_pattern, :automation_tag
  validates_uniqueness_of :automation_tag

  def to_tree
    {
			:id => self.id,
			:name => self.name,
			:command_pattern => self.command_pattern,
			:automation_tag => self.automation_tag
	  }
  end
end
