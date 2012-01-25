class JiraRequirement < JiraIssue
  set_inheritance_column nil
  default_scope :conditions => "(select pname from issuetype where ID = jiraissue.issuetype) = 'Requirement'"
end
