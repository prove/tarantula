=begin rdoc

Backup does a zip backup of database and attachments. 

=end
class ZipAttachments
  time = Time.now.strftime "%Y%m%d"
  BACKUP_ZIP = File.join(Rails.root, 'tmp', 'backup'+time+'.zip')

  def process
    attachment_files = Dir.glob(File.join(Rails.root, 'attachment_files', '*'))
    FileUtils.rm_f BACKUP_ZIP

    Zip::ZipFile.open(BACKUP_ZIP, Zip::ZipFile::CREATE) do |zipfile|
      attachment_files.each do |filename|
        zipfile.add(File.basename(filename), filename)
      end
    end
  end

  private

end
