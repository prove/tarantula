=begin rdoc

A class for input sanitation. params[:data] is run through #clean_data

=end
class Sanitizer
  include Singleton
  include ActionView::Helpers::SanitizeHelper
  include ActionView::Helpers::TagHelper
  
  public
  
  def clean_data(data)
    case data.class.to_s
    when 'Hash'
      h = {}
      data.each do |k,v|
        h.merge!({k => clean_data(v)})
      end
      return h
    when 'Array'
      return data.map{|d| clean_data(d)}
    when 'String'
      return sanitize(data)
    else
      return data
    end
  end
  
  private
  def self.white_list_sanitizer
    full_sanitizer
  end
  def self.full_sanitizer
    @@sanitizer ||= HTML::FullSanitizer.new
  end
end
