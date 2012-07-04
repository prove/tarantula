class JiraProject < ActiveRecord::Base
  self.table_name = 'project'
  self.primary_key = 'ID'

  has_many :issues, :class_name => 'JiraIssue', :foreign_key => 'PROJECT'

  def name
    self['pname']
  end

  def external_id
    self['ID']
  end

end
