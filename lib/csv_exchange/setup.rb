module CsvExchange
  class Setup
    def initialize(csv_setup)
      @csv_setup = csv_setup
      @csv_setup[:cells] = []
      @csv_setup[:children] = []
      @csv_setup[:identifier] = nil
      @csv_setup[:after_update] = nil
    end
    
    def attribute(name, title, opts={})
      @csv_setup[:cells] << {:name => name, :title => title, 
                             :type => :attribute, :opts => opts}
      if opts[:identifier]
        raise "Can't have multiple identifiers" if @csv_setup[:identifier]
        @csv_setup[:identifier] = {:name => name, 
                                   :index => @csv_setup[:cells].size - 1}
      end
    end
    
    def association(name, title, opts={})
      raise "Association map required" unless opts[:map]
      @csv_setup[:cells] << {:name => name, :title => title, 
                             :type => :association, :opts => opts}
    end

    def field(name, title)
      @csv_setup[:cells] << {:name => name, :title => title, :type => :field}
    end

    def children(name)
      unless @csv_setup[:children].empty?
        raise "Multiple children classes not supported yet"
      end
      @csv_setup[:children] << name
    end
    
    def after_update(&block)
      @csv_setup[:after_update] = block
    end

  end
end
