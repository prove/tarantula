class UpdateMysqlToMysql2InImportSources < ActiveRecord::Migration
  def up
    sources = ImportSource.where(:adapter => 'mysql')
    sources.each do |s|
      s.update_attribute(:adapter, 'mysql2')
    end
  end

  def down
  end
end
