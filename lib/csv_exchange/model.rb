module CsvExchange
  
  module Model
    
    def define_csv(&block)
      @csv_setup = Hash.new
      CsvExchange::Setup.new(@csv_setup).instance_eval(&block)
      include InstanceMethods
    end
    
    def csv_setup
      @csv_setup
    end

    def csv_header(col_sep=';', row_sep="\r\n", opts={})
      CSV.generate(:col_sep => col_sep, :row_sep => row_sep) do |csv|
        row = []
        row = [''] * opts[:indent] if opts[:indent]
        @csv_setup[:cells].each do |cell|
          row << cell[:title]
        end
        csv << row
      end
    end

    module InstanceMethods
      def to_csv(col_sep=';', row_sep="\r\n", opts={})
        
        ret = CSV.generate(:col_sep => col_sep, :row_sep => row_sep) do |csv|
          row = []
          row = [''] * opts[:indent] if opts[:indent]
          
          self.class.csv_setup[:cells].each do |cell|
            case cell[:type]
            when :attribute
              row << send(cell[:name])
            when :association
              records = [send(cell[:name])].flatten
              data = records.map{|rec| rec.send(cell[:opts][:map])}
              data = data.map(&:to_s).join(', ')
              row << data
            when :field
              row << send(cell[:name])
            end
          end
          csv << row
        end
        
        if opts[:recurse] and opts[:recurse] > 0 and !self.class.csv_setup[:children].empty?
          new_opts = opts.dup
          new_opts[:recurse] -= 1
          new_opts[:indent] ||= 0
          new_opts[:indent] += 1
          self.class.csv_setup[:children].each do |ch|
            ch_class = ch.to_s.singularize.camelize.constantize
            ret += ch_class.csv_header(col_sep, row_sep, new_opts)
            ret += send(ch).map{|c| c.to_csv(col_sep, row_sep, new_opts)}.join
          end
        end
        ret
      end
    end
    
  end

end
