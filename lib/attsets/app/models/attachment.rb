=begin rdoc

=Attachment
A simple save-once destroy-never attachment.

=end
class Attachment < ActiveRecord::Base
  # Currently we are not using X-Accel-Redirect or X-Sendfile headers
  # TODO: If current send_file implementation block app server, fix me
  #if RAILS_ENV == 'production'
  #  ACCESS_PATH = '/attachment_files' # under the public
  #  FILE_PATH = File.join(RAILS_ROOT, 'attachment_files')
  #else
  ACCESS_PATH = FILE_PATH = File.join(Rails.root, 'attachment_files')
  #end

  attr_accessor :file_data

  has_and_belongs_to_many :attachment_sets
  validates_presence_of :orig_filename
  after_save :save_file

  before_destroy { raise "Not meant to be destroyed" }
  before_save{|a|
    raise "Save once" unless a.new_record?
    raise "file_data required" unless a.file_data
  }

  def filename
    return nil if self.new_record?
    "#{self.id}#{File.extname(self.orig_filename).downcase}"
  end

  def access_path
    File.join(ACCESS_PATH, self.filename)
  end

  def file_path
    File.join(FILE_PATH, self.filename)
  end

  def to_data
    {:name => self.orig_filename, :id => self.id}
  end

  # for windows compatibility
  def get_basename(str)
    ret = str.split('\\').last.split('/').last
  end

  def file_data=(file_data)
    raise "Attachment reflects one file!" unless self.new_record?

    if file_data.is_a?(Array) # [name, Tempfile]
      self.orig_filename = get_basename(file_data[0])
      @file_data = file_data[1]
    elsif file_data.is_a?(File)
      self.orig_filename = get_basename(file_data.path)
      @file_data = file_data
    elsif file_data.respond_to?(:read) # StringIO, PhusionPassenger::Utils::RewindableInput etc
      self.orig_filename = 'chart.png'
      @file_data = file_data
    else
      raise "Invalid type for file_data (#{@file_data.class.to_s})"
    end
  end

  private

  def save_file
    FileUtils.mkdir_p(FILE_PATH) # make the dir if necessary

    # TODO: just move the file if using nginx upload module
    File.open(self.file_path, 'wb') do |file|
      file.puts @file_data.read
    end
  end

end
