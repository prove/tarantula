class DropCaseCategories < ActiveRecord::Migration
  def self.up
    tables = ActiveRecord::Base.connection.tables
    drop_table(:case_categories) if tables.include?('case_categories')
  end

  def self.down
    create_table :case_categories do |t|
    end
  end
end
