module Report
=begin rdoc

Report: Dashboard. A composite report of preferred items.

=end  
  class Dashboard < Report::Base

    # could also take project_assignment_id but assignments
    # seem too volatile
    def initialize(user_id, project_id, test_area_id, test_object_id)
      @name = "Dashboard"
      @options = {:user_id => user_id,
                  :project_id => project_id,
                  :test_area_id => test_area_id,
                  :test_object_id => test_object_id
                 }
    end
    
    def expires_in; 60.minutes; end
    
    def to_pdf; raise "no pdf available!"; end
    def to_csv(*args); raise "no csv available!"; end
    def as_json(options=nil)
      self.query unless @data
      @data.map do |comp_set|
        {:type => 'report', :components => comp_set}.as_json(options)
      end
    end
    
    protected
  
    def do_query
      user = User.find(@options[:user_id])
      project = Project.find(@options[:project_id])
      
      pref = user.preferences.dashboard.for_project(project).first
      pref ||= Preference::Dashboard.default(user, project)
      
      @data = []
      pref.items.each {|i| @data << i.to_report(user, project).to_data}
    end
  
  end # class Dashboard

end # module Report
