class Report::Excel

  def initialize(report)
    @report = report
  end

  def render
    book = ::Spreadsheet::Workbook.new
    sheet = book.create_worksheet
    row = 0
    @report.components.each do |c|
      if c.class == Report::Component::Text and c.sub_type.to_s =~ /h[2-9]/
        row += 1
      end
      # Create new sheet when page break is encountered
      if c.class == Report::Component::Formatting and c.format[:page_break]
        sheet = book.create_worksheet
        row = 0
      elsif c.respond_to?(:to_spreadsheet)
        row = c.to_spreadsheet(sheet, row).first + 1
      end
    end

    # Return spreadsheet as binary string for download
    data = StringIO.new
    book.write(data)
    data.string
  end

end
