
module Report
  module Component

    # Component for pdf formatting
    class Formatting
      attr_reader :format

      def initialize(format_hash)
        @format = format_hash
      end

      def as_json(options=nil)
        {:type => 'format',
         :format => @format}.as_json(options)
      end

      def to_pdf(pdf)
        # do pdf_formatting according to format_hash
        pdf.start_new_page if @format[:page_break]
        pdf.text_options.update(@format[:text_options]) \
          if @format[:text_options]
        pdf.move_down(@format[:pad]) if @format[:pad]
      end

    end

  end # module Component
end # module Report
