
module SmartTag
  
  class Best
    def self.name; 'Best' end
    
    def self.conditions(klass, project, test_area)
      counts = (test_area || project).cases.active.\
        find(:all, :select => 'id, updated_at, project_id').map do |c|
        [c.id, c.linked_bug_ids(test_area).size]
      end.select{|c| c[1] > 0}
      
      c_ids = counts[0, 10].map{|c| c[0]}
      
      c_ids = ['NULL'] if c_ids.empty?
      "cases.id IN (#{c_ids.join(',')})"
    end
    
    def self.joins; nil end
    
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