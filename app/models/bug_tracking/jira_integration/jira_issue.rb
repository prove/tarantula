  class JiraIssue < ActiveRecord::Base
  UDMargin = 5.minutes # update margin
  self.table_name = 'jiraissue'
  self.primary_key = 'id'

  belongs_to :project, :class_name => 'JiraProject', :foreign_key => 'project'
  belongs_to :priority, :class_name => 'JiraPriority', :foreign_key => 'priority'
  belongs_to :status, :class_name => 'JiraStatus', :foreign_key => 'issuestatus'

  scope :recent_from_projects, lambda {|prids, last_fetched, force_update|
    conds = "PROJECT IN (#{prids.join(',')})"
    c = CustomerConfig.jira_defect_types
    if c
      types = c
    else
      types = BT_CONFIG[:jira][:defect_types]
    end
    conds += " AND (select pname from issuetype where id = jiraissue.issuetype) " +
        "IN (#{types.map{|t|"'%s'"%t}.join(',')})"
    unless force_update
      conds += " AND ((UPDATED IS null) OR "+
        "(UPDATED >= '#{(last_fetched-UDMargin).to_s(:db)}'))"
    end
    where(conds)
  }

  scope :from_projects, lambda {|prids|
    where('project' => prids)
  }

  def to_data
    {
      :lastdiffed => self['updated'],
      :external_id => self['id'],
      :name => self['summary'],
      :status => self.status.value,
      :desc => self['description']
    }
  end

  def updated
    self['updated']
  end

  def summary
    self['summary']
  end

  def desc
    self['description']
  end

  def url_part
    self['pkey']
  end

end
