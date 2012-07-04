module Report
  
  # POST:able report data for editable report fields
  class Data < ActiveRecord::Base
    self.table_name = 'report_data'
    belongs_to :user
    belongs_to :project
    
    validates_presence_of :project_id, :user_id
    
    def data=(d)
      self['data'] = YAML.dump(d)
    end
  
    def data
      self['data'].nil? ? nil : YAML.load(self['data'])
    end
  end
  
end
