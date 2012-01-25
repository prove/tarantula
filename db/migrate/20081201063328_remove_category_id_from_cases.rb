class RemoveCategoryIdFromCases < ActiveRecord::Migration
  def self.up
    if Case.columns.detect {|c| c.name == 'case_category_id'}
      remove_column :cases, :case_category_id
      remove_column :case_versions, :case_category_id
    end    
  end

  def self.down
  end
end
