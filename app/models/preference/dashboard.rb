
module Preference
  
  # Dashboard preferences.
  class Dashboard < Preference::Base
    # dashboard preferences are always project_specific!
    validates_presence_of :project_id, :user_id
    
    def items
      items = []
      self.data.each do |item_id|
        item = DashboardItem.find(item_id.to_sym)
        items << item if item
      end
      items
    end
    
    def self.default(user, project)
      self.new(:data => [:overview, 
                         :daily_progress,
                         :summary, 
                         :results,
                         :bugs,
                         :my_tasks],
               :user => user)
    end
  end
  
end # module Preference
