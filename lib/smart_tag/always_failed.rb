
module SmartTag
  
  class AlwaysFailed
    
    def self.name; 'AlwaysFailed' end
    
    def self.conditions(klass, project, test_area)
      "EXISTS (SELECT id FROM case_executions WHERE case_id="+
      "cases.id AND result='#{::Failed}') AND NOT EXISTS "+
      "(SELECT id FROM case_executions WHERE case_id="+
      "cases.id AND result IN ('#{::Passed}', '#{::NotImplemented}'))"
    end
    
    def self.joins; 'LEFT JOIN case_executions ON case_executions.case_id=cases.id' end
    
    # return [tags, smart_tags] which this smart tag is allowed with
    def self.filter_allowed(tags, smart_tags)
      [tags, []]
    end
    
    def self.to_tree
      { :text => self.name,
        :dbid => self.name,
        :leaf => false,
        :cls => 'folder x-listpanel-smarttag' }
    end
  end
end