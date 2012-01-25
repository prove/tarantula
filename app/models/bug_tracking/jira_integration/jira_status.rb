class JiraStatus < ActiveRecord::Base
  set_table_name 'issuestatus'
  set_primary_key 'ID'

  has_many :issues, :class_name => 'JiraIssue', :foreign_key => 'issuestatus'

  def value
    self.pname
  end

  def value=(val)
    self.pname = val
  end
end
