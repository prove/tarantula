require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Backup do
  describe ".process" do

    it "should include mysqldump into the zip file" do
      backup = Backup.new
      backup.process

      zip = Zip::ZipFile.open(Backup::BACKUP_ZIP)
      zip.should_not be_nil

      entry = zip.find_entry("database_backup.sql")
      entry.should_not be_nil
      entry.get_input_stream do |f|
        f.read(100).length.should > 0
      end
    end
  end
end
