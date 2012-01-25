class ImportCategoriesAsTags < ActiveRecord::Migration


  # Original CaseCategory model is probably removed already when
  # this migration is executed, so simplified CaseCategory is
  # declared here instead.
  class CaseCategory < ActiveRecord::Base
    has_many :cases, :conditions => {:deleted => false}
  end

  
  def self.up
    user = User.find(1)
    user.current_user = user 

    # Locate cases assigned to categories, which
    # do not exist anymore. Move these to delete folder.
    cases = Case.find(:all)
       
    cases.each { |c|
      category_id = c[:case_category_id]
      
      if category_id == nil or category_id == 0
        # Root level, skipped
        next
      end
      
      begin
        cat = CaseCategory.find(category_id)
      rescue
        puts "\n\nCategory id for case not found: #{category_id}"
        puts "Setting case as deleted: #{c.id} #{c.title}"
        c.update_attribute( 'deleted', true)
        c.update_attribute( 'title', c[:title] + " [FROM DELETED CATEGORY]")
      end
    }

    
    require File.dirname(__FILE__) + '/../../app/models/tag.rb'
 	   
 	   
    cats = CaseCategory.find(:all, :include => :cases)
    cats.each{|t|
      puts "Converting #{t.name} to tags..."
      t.cases.each{|c|
        c.tag_with(t.name)
      }
    } 
    
    remove_column :cases, :case_category_id
    remove_column :case_versions, :case_category_id
    drop_table :case_categories
    
  end

  def self.down
    create_table :case_categories do |t|
      t.column :name, :string
      t.column :parent_id, :integer
    end
    add_column :cases, :case_category_id, :integer
    add_column :case_versions, :case_category_id, :integer
  end
end
