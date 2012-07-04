
module Report
  module Component

    # Text component, optionally editable.
    class Text
      VALID_SUBTYPES = [:h1, :h2, :h3, :p]

      attr_accessor :sub_type, :editable, :key

      def initialize(subtype, value, editable=false, alt=nil)
        raise "Invalid subtype (#{sub_type})!" \
          unless VALID_SUBTYPES.include?(subtype)

        @sub_type, @value, @editable, @alt = subtype, value, editable, alt
      end

      def value; @value; end
      def value=(new_val)
        raise "Not editable!" unless self.editable
        raise "No key specified" unless self.key
        @value = new_val
      end

      def as_json(options=nil)
        ret  = {:type     => "text_#{sub_type}",
                :value    => @value,
                :editable => @editable}
        ret.merge!(:key => self.key) if self.key
        ret.as_json(options)
      end

      def to_pdf(pdf)
        if @sub_type == :h1
          pdf.pad_bottom(30) do
            pdf.font "#{Rails.root}/vendor/fonts/DejaVuSans-Bold.ttf"
            pdf.text @value, :size => 18, :align => :center
            pdf.font "#{Rails.root}/vendor/fonts/DejaVuSans.ttf"
          end
        elsif @sub_type == :h2 or @alt == :big
          pdf.pad_top(20) do
            pdf.pad_bottom(15) do
              pdf.text @value, :size => 14
              pdf.stroke_horizontal_rule if @sub_type == :h2
            end
          end
        elsif @sub_type == :h3
          pdf.pad_top(20) { pdf.pad_bottom(10) { pdf.text @value, :size => 12 } }
        else
          pdf.text @value
        end
      end

      # Return last affected row and col
      def to_spreadsheet(sheet, row=0, col=0)
        format_opts = {}
        if @sub_type == :h1
          sheet.name = @value
          format_opts[:size] = 18
          sheet.row(row).height = 20
        elsif @sub_type == :h2 or @alt == :big
          format_opts[:size] = 14
          sheet.row(row).height = 16
        elsif @sub_type == :h3
          format_opts[:size] = 12
        end
        sheet.row(row).set_format(0, ::Spreadsheet::Format.new(format_opts))
        sheet.row(row).push @value

        [row,col]
      end

    end

  end # module Component
end # module Report
