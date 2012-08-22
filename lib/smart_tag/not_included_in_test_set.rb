
module SmartTag
  
  class NotIncludedInTestSet
    
    def self.name; 'NotIncludedInTestSet' end
    
    def self.conditions(klass, project, test_area)
      container = test_area || project
      test_sets = container.test_sets
      case_ids = test_sets.map(&:cases).flatten.uniq.map(&:id).map(&:to_s)
      if case_ids.empty?
        "cases.id IS NOT NULL"
      else
        "cases.id NOT IN (#{case_ids.join(',')}) OR test_sets.deleted=true"
      end
    end

    def self.joins
      "LEFT JOIN cases_test_sets ON cases.id=cases_test_sets.case_id "+
      "AND cases.version=cases_test_sets.version "+
      "LEFT JOIN test_sets ON test_sets.id=cases_test_sets.test_set_id "+
      "AND test_sets.version=cases_test_sets.test_set_version"
    end
    
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
