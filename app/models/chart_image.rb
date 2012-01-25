=begin rdoc

A user uploaded chart image.

Stores the chart_image_key in 'data' attribute, consisting of:
* the cache_key of the report this image belongs to
* index number (e.g., 2 => 3rd component in report)

N.B Report::Base sets the chart image key for each chart component

=end
class ChartImage < Attachment # STI
  validates_presence_of :data
  
  # Create a chart image key
  def self.create_key(rep_cache_key, component_index)
    "#{rep_cache_key}_#{component_index}"
  end
  
  # removes this chart image and the file
  # (against the destroy-never principle of superclass)
  def expire!
    FileUtils.rm_f file_path
    ChartImage.delete(self.id)
  end
end
