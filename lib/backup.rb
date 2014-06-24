=begin rdoc

Backup does a zip backup of database and attachments.

=end
class Backup
  BACKUP_ZIP = File.join(Rails.root, 'tmp', 'backup.zip')

  def process
    tmp_dir = File.join(Rails.root, 'tmp')
    Dir.mkdir(tmp_dir) unless File.exists?(tmp_dir)

    attachment_files = Dir.glob(File.join(Rails.root, 'attachment_files', '*'))
    db_backup = File.join(tmp_dir, 'database_backup.sql')
    if db_conf['password'].blank?
      passwd = ''
    else
      passwd = "-p #{db_conf['password']}"
    end

    system "mysqldump #{db_conf['database']} -u #{db_conf['username']} #{passwd} > #{db_backup}"

    FileUtils.rm_f BACKUP_ZIP

    Zip::ZipFile.open(BACKUP_ZIP, Zip::ZipFile::CREATE) do |zipfile|
      attachment_files.each do |filename|
        zipfile.add(File.basename(filename), filename)
      end
      zipfile.add(File.basename(db_backup), db_backup)
    end
  end

  private

  def db_conf
    Rails.configuration.database_configuration[Rails.env]
  end
end
