
module SmartTag
  
  class NotImplemented
    def self.name; 'NotImplemented' end
    
    def self.conditions(klass, project, test_area)
      container = test_area || project
      current_to = container.test_objects.active.first
      to_ids = container.test_objects.active.find(:all).map(&:id)
      cases = container.cases.active.find(:all, 
                                   :conditions => ['date <= :date', {:date => current_to.try(:date)}],
                                   :select => 'id, updated_at')
      c_ids = cases.select{|c| c.last_results(to_ids, test_area).first == ::NotImplemented}.map{|c| c.id.to_s}
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