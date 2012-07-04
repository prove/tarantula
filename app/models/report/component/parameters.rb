
module Report
  module Component

    # Component of report parameters shown to users.
    class Parameters
      attr_accessor :parent_name, :name

      def initialize(report_name, key_val_arrs)
        @phash = ActiveSupport::OrderedHash.new
        @name = report_name
        @parent_name = nil

        key_val_arrs.each do |k,v|
          next if v.blank?
          if v.is_a?(String)
            v_val = v
          elsif v.respond_to?(:name)
            v_val = v.name
          else
            v_val = v
          end
          @phash[k] = v_val
        end
      end

      def value; @phash; end

      def name
        if @parent_name
          return "#{@parent_name} / #{@name}"
        end
        @name
      end

      def as_json(options=nil)
        {:type     => "parameters",
         :value    => @phash}.as_json(options)
      end

      def to_pdf(pdf)
        pdf.header([pdf.margin_box.left, pdf.margin_box.top + 60]) do
          pdf.text_options.update(:size => 8)

          pdf.table [[name, pdf.page_count.to_s, Time.now.to_s(:short)] + @phash.values],
              {:headers => ['Report', 'Page', 'Generated At'] + @phash.keys,
               :align => :left,
               :border_style => :underline_header,
               :vertical_padding => 0,
               :horizontal_padding => 2,
               :align => :center,
               :position => :center}

          pdf.text_options.update(:size => 10)
        end
      end

      def to_spreadsheet(sheet, row=0, col=0)
        sheet.row(row).default_format = ::Spreadsheet::Format.new(:size => 8,
                                                                  :weight => :bold,
                                                                  :pattern_fg_color => :gray,
                                                                  :pattern => 1)
        sheet.row(row+1).default_format = ::Spreadsheet::Format.new(:size => 8)

        sheet.row(row).replace ['Report', 'Generated At'] + @phash.keys

        r = [name, Time.now.to_s(:short)] + @phash.values
        sheet.row(row+1).replace r

        # Ensure that column widths are adequate
        r.each_index do |i|
          sheet.column(col+i).width = [sheet.column(col+i).width, r[i].to_s.length+2].max
        end

        [row+1,col]
      end

    end

  end # module Component
end # module Report
