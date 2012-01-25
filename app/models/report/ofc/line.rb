module Report
  
  module OFC
    
    # OFC line graph
    class Line < Report::OFC::Base
      
      class Multi < Line
        def initialize(data, x_labels)
          @chart = {}
          @chart[:type] = 'chart'
          @chart[:bg_colour] = "#ffffff"
          @chart[:y_axis] = {:max => 100, :steps => 10}
          @chart[:x_axis] = {:labels => {:size => 12,
                                         :rotate => 'diagonal',
                                         :labels => x_labels}}
          set_y_legend("Percentage (%)")
          
          passed = data[0]
          not_impl = data[1]
          
          add_line(passed, "Passed", Passed.color)
          add_line(not_impl, "Not Implemented", NotImplemented.color)
        end
        
        def add_line(vals, text, color)
          @chart[:elements] ||= []
          @chart[:elements] << {:values => vals, :text => text, 
                                :type => 'line', :colour => color,
                                'dot-size' => 3,
                                'dot-style' => {:type => 'solid-dot', 
                                                'dot-size' => 3,
                                                'halo-size' => 1,
                                                :colour => color},
                                :width => 1, 'font-size' => 10}
        end
      end
      
    end
  end
  
end
