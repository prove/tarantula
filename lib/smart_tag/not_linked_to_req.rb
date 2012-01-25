module SmartTag

  # Lists cases which are not linked to any requirement
  #
  # Usable with following models: Case
  class NotLinkedToReq
    def self.name; 'NotLinkedToRequirement' end

    def self.conditions(klass, project, test_area)
      "NOT EXISTS (SELECT requirements.id FROM "+
        "cases_requirements, requirements WHERE "+
        "cases_requirements.case_id=#{klass.table_name}.id AND " +
        "cases_requirements.requirement_version = requirements.version AND "+
        "cases_requirements.requirement_id = requirements.id)"
      
    end

    def self.joins; nil end

    def self.filter_allowed(tags, smart_tags)
      [tags, smart_tags.select{|i|i!=self}]
    end

    def self.to_tree
      {
        :text => self.name,
        :dbid => self.name,
        :leaf => false,
        :cls => 'folder x-listpanel-smarttag'
      }
    end
  end
end
