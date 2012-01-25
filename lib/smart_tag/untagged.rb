
module SmartTag
  
  class Untagged
    def self.name; 'Untagged' end
    
    def self.conditions(klass, project, test_area)
      "NOT EXISTS (SELECT id FROM taggings WHERE taggable_id="+
      "#{klass.table_name}.id AND taggable_type='#{klass.to_s}')"
    end
    
    def self.joins; nil end
    
    # return [tags, smart_tags] which this smart tag is allowed with
    def self.filter_allowed(tags, smart_tags)
      [[], []]
    end
    
    def self.to_tree
      { :text => self.name,
        :dbid => self.name,
        :leaf => false,
        :cls => 'folder x-listpanel-smarttag' }
    end
  end
end