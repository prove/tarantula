
module Report
  module Component

    # Table component.
    class Table
      attr_accessor :columns, :data, :csv_export_url

      def initialize(columns,data,opts={})
        @columns = columns
        @data = data
        if opts.delete(:overview)
          @type = 'table_overview'
        elsif opts.delete(:collapsable)
          @type = 'table_collapsable'
        else
          @type = 'table'
        end
        @opts = opts
        @csv_export_url = nil
      end

      def empty?
        @data.flatten.empty?
      end

      def as_json(options=nil)
        ret = {:type    => @type,
               :columns => @columns.map{|k,v| [k,v]},
               :data    => @data}
        ret.merge!(:csv_export_url => @csv_export_url) if @csv_export_url
        ret.as_json(options)
      end

      def to_csv(delimiter=';', line_feed="\r\n")
        csv = ""
        csv << '"' + @columns.map{|c| c[1]}.join('"'+delimiter+'"')+'"'
        csv << line_feed
        col_keys = @columns.map{|c| c[0]}

        @data.each do |row|
          col_keys.each do |ck|
            csv << '"'+row[ck].to_s+'"' + delimiter
          end
          csv.chop!
          csv << line_feed
        end
        csv
        #"\xEF\xBB\xBF"+csv # Byte-order mark
      end

      def to_pdf(pdf)
        return if self.empty?

        tdata = @data.map do |row|
          @columns.map do |ck,cn|
            ERB::Util.html_escape row[ck]
          end
        end
        pdf.pad_bottom(10) do
          pdf.pad_top(5) do
            pdf.table tdata,
                {:headers => @columns.map{|c| ERB::Util.html_escape c[1] },
                 :row_colors => ['ffffff', 'eeeeee'],
                 :align => :left,
                 :horizontal_padding => 10}.merge(@opts)
          end
        end
      end

      def to_spreadsheet(sheet, row=0, col=0)
        return [row, col] if self.empty?

        tdata = @data.map do |r|
          @columns.map{|k,n| r[k]||""}
        end

        sheet.row(row).default_format = ::Spreadsheet::Format.new :weight => :bold

        ([@columns.map{|c| c[1]}] + tdata).each do |r|
          # Ensure that column widths are adequate
          r.each_index do |i|
            sheet.column(col+i).width = [sheet.column(col+i).width, r[i].to_s.length+2].max
          end
          sheet.row(row).replace r
          row += 1
        end
        return [row,col]
      end

      # removes rows where value of all keys is zero
      def remove_zero_rows(keys)
        keys = [keys] unless keys.is_a?(Array)
        @data = data.select do |row|
          vals = keys.map{|k| row[k] != 0 }
          vals.include?(true)
        end
      end

    end

  end # module Component
end # module Report
