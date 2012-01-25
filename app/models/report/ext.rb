module Report

=begin rdoc

Report extension module.

=end  
  module Ext
  
    # link to specific area of UI
    def self.ui_link_for(resource)
      return nil if !resource
      "design#{resource.class.to_s.pluralize.downcase}"
    end
    
    # report specific link
    def self.rep_link_for(resource, col_key, target=nil)
      target ||= ui_link_for(resource)
      {col_key => {:target => target, :id => resource.id}}
    end
    
    def fatal(cond, msg)
      text("FATAL: #{msg}") if cond
      return cond
    end
    
  end

end # module Report