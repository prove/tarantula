class JiraProject < ActiveRecord::Base
  self.table_name = 'project'
  self.primary_key = 'id'

  has_many :issues, :class_name => 'JiraIssue', :foreign_key => 'project'

  def name
    self['pname']
  end

  def external_id
    self['id']
  end

end
