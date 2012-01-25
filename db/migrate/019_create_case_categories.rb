class CreateCaseCategories < ActiveRecord::Migration
  def self.up
    create_table :case_categories do |t|
    end
  end

  def self.down
    drop_table :case_categories
  end
end
