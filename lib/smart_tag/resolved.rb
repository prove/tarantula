
module SmartTag
  
  class Resolved
    def self.name; 'Resolved' end
    
    def self.conditions(klass, project, test_area)
      c_ids = []
      
      bt = project.bug_tracker
      raise "No bug tracker" unless bt
      
      bt_type = bt[:type].downcase        
      cc = CustomerConfig.find(:first, :conditions => {
                                 :name => bt_type.downcase + '_fixed_statuses'})
      if cc
          statuses = cc.value
      else
        statuses = BT_CONFIG[bt_type.to_sym][:fixed_statuses]
      end
            
      (test_area || project).cases.active.\
        find(:all, :select => 'id, updated_at, project_id').each do |c|
        
        linked_bug_ids = c.linked_bug_ids(test_area)
        next if linked_bug_ids.empty?
        
        resolved = Bug.find(:all, :conditions => {:id => linked_bug_ids, :status => statuses},
                            :select => 'id')
        c_ids << c.id if !resolved.empty?
      end
      
      c_ids = ['NULL'] if c_ids.empty?
      SmartTag::Failed.conditions(klass, project, test_area) + " AND cases.id IN (#{c_ids.join(',')})"
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
