module Report

=begin rdoc

A user-generated pdf-report.

=end
class PDF

  def initialize(report, pdf_options={})
    @report = report
    @pdf_options = pdf_options
  end

  def render
    opts = {:page_size => 'A4', :top_margin => 70}
    opts.merge!(@pdf_options[:opts_for_new]) if @pdf_options[:opts_for_new]
    pdf = Prawn::Document.new(opts)
    pdf.font "#{Rails.root}/vendor/fonts/DejaVuSans.ttf"
    pdf.stroke_color = '777777'

    @pdf_options[:init].call(pdf) if @pdf_options[:init]

    # let each component render itself
    @report.components.each {|c| c.to_pdf(pdf)}
    pdf.render
  end

end


end # module Report
