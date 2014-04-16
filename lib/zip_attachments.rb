=begin rdoc

Backup does a zip backup of database and attachments. 

=end
class ZipAttachments
  ATTACHMENT_ZIP = File.join(Rails.root, 'attachments'+time+'.zip')

  def process
    attachment_files = Dir.glob(File.join(Rails.root, 'attachment_files', '*'))
    
    Zip::ZipFile.open(ATTACHMENT_ZIP, Zip::ZipFile::CREATE) do |zipfile|
      attachment_files.each do |filename|
        zipfile.add(File.basename(filename), filename)
      end
    end
  end
end
