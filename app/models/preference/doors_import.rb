module Preference
  
  # Dashboard preferences.
  class DoorsImport < Preference::Base
    # one per project
    validates_presence_of :project_id
    
    def self.default(project)
      self.new(:data => {
                         :requirement_tag_enabled => "0", 
                         :requirement_tag_level   => "1", 
                         
                         :requirement_enabled     => "0", 
                         :requirement_min         => "2", 
                         :requirement_max         => "10", 
                         
                         :set_enabled             => "0", 
                         :set_level               => "1", 
                         
                         :case_tag_enabled        => "0", 
                         :case_tag_level          => "1", 
                         
                         :case_enabled            => "0", 
                         :case_min                => "2", 
                         :case_max                => "10",
                         
                         :max_object_level        => "10", 
                         :test_area               => "",
                         :tags                    => "" },
               :project => project)
    end
  end
  
end