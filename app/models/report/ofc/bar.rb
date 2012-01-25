
module Report
  module OFC
    
    # OFC Bar graph
    class Bar < Report::OFC::Base
      def no_data?
        return true unless @chart[:elements]
        return true if @chart[:elements].empty?
        [[0],[]].include?(@chart[:elements].map{|e| e[:values]}.flatten.uniq)
      end
      
      class Results < Bar
        def initialize(title, cols, rows, *opts)
          labels = cols.reject{|k,v| k == :name}.map{|k,v| v}
          y_max = rows.reject{|r| r[:name] == 'Total'}.map(&:values).\
            flatten.select{|v| v.is_a?(Integer)}.max
          set_defaults(title, labels, y_max, opts)
          set_elements(cols, rows)
        end
        
        private
        def set_elements(cols, rows)
          elems = []
          keys = cols.reject{|k,v| k == :name}.map{|k,v| k}

          rows.reject{|r| r[:name] == 'Total'}.each do |r|
            elem = {:values => [], :type => 'bar', :text => r[:name],
                    :colour => ResultType.send(r[:name]).color,
                    'font-size' => 10, :tip => "\#val\# #{r[:name]}"}
            keys.each do |key|
              elem[:values] << r[key]
            end
            elems << elem
          end
          @chart[:elements] = elems
        end
      end # Results
      
    end # Bar
    
  end # OFC
  
end # Report