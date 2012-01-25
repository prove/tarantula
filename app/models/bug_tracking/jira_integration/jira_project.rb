class JiraProject < ActiveRecord::Base
  set_table_name 'project'
  set_primary_key 'ID'

  has_many :issues, :class_name => 'JiraIssue', :foreign_key => 'PROJECT'

  def name
    self['pname']
  end

  def external_id
    self['ID']
  end

end
