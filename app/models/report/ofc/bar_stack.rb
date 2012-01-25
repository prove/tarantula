
module Report
  module OFC  
    
    # OFC Bar stack graph
    class BarStack < Report::OFC::Base
     
      def no_data?
        return true unless @chart[:elements]
        return true if @chart[:elements].empty?
        return true unless @chart[:elements].first[:values].first
        vals = @chart[:elements].first[:values].flatten
        vals.map!{|val| val.is_a?(Hash) ? val[:val] : val}
        vals.uniq == [0]
      end
      
      # sets tool tip by result type
      def set_tooltip_by_result_type
        replaces = { }
        val_arrs = @chart[:elements].first[:values]
        val_arrs.each_with_index do |arr, i|
          arr.each_with_index do |val,j|
            color = ResultType.send(@chart[:elements].first[:text][j].to_sym).color
            if color
              replaces[[i,j]] = { 
                :val => val, 
                :colour => color, 
                :tip => "#{@chart[:elements].first[:text][j]}: #{val}"} 
            end
          end
        end
        @chart[:elements].first.delete(:text)
        replaces.each do |k,v|
          val_arrs[k[0]][k[1]] = v
        end
      end
      
      # performs a conversion:
      # [{:a => 1, :b => 2}, {:a => 8, :b => 9}] => [[1,8], [2,9]]
      def self.values_from_table_rows(rows, keys)
        vals = []
        keys.each do |k|          
          vals << rows.map{|r| r[k]}
        end
        vals
      end      
    end # class BarStack
  end # Module OFC
end # Module Report
