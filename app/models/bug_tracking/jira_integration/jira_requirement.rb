class JiraRequirement < JiraIssue
  self.inheritance_column = nil
  default_scope :conditions => "(select pname from issuetype where id = jiraissue.issuetype) = 'Requirement'"
end
