class JiraPriority < ActiveRecord::Base
  set_table_name 'priority'
  set_primary_key 'ID'

  has_many :issues, :class_name => 'JiraIssue', :foreign_key => 'priority'

  def value
    self.pname
  end

  def value=(val)
    self.pname = val
  end

  def external_id
    self['ID']
  end

  def sortkey
    self['SEQUENCE']
  end
end
