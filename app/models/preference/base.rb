
module Preference
  
  # Preference base class.
  class Base < ActiveRecord::Base
    self.table_name = 'preferences'
    belongs_to :user
    belongs_to :project # optional
    
    scope :dashboard, where(:type => 'Dashboard')
    scope :for_project, lambda {|p| where(:project_id => p.id)}
    
    # Serializing assignment
    def data=(d)
      self['data'] = YAML.dump(d)
    end
    # Unserializing read
    def data
      self['data'].nil? ? nil : YAML.load(self['data'])
    end
  end
  
end # module Preference
