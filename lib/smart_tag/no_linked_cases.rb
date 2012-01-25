module SmartTag

  # Lists requirements which don't have any related cases.
  #
  # Usable with following models: Requirement
  class NoLinkedCases
    def self.name; 'NoLinkedCases' end

    def self.conditions(klass, project, test_area)
      "NOT EXISTS (SELECT case_id FROM cases_requirements WHERE requirement_id="+
        "#{klass.table_name}.id AND requirement_version = #{klass.table_name}.version)"
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
