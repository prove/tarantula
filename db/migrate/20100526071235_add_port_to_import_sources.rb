class AddPortToImportSources < ActiveRecord::Migration
  def self.up
    add_column :import_sources, :port, :integer
  end

  def self.down
    remove_column :import_sources, :port
  end
end
