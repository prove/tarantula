class ScopeTagsToProjectAndTaggableType < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :tags, :project_id, :integer
      add_column :tags, :taggable_type, :string
      remove_index :tags, :name
      
      ### DATA MIGRATION ###
      
      Project.all.each do |proj|    
        # Assignments
        # we have to change tag ids in default tags..    
        proj.assignments.each do |a|
          if a.default_tag_id
            if tag = Tag.find_by_id(a.default_tag_id)
              new_tag = Tag.find(:first, :conditions => {:name => tag.name,
                :project_id => proj.id, :taggable_type => 'Project'})
              unless new_tag
                new_tag = Tag.create(:name => tag.name, :project_id => proj.id,
                                      :taggable_type => 'Project')                
              end
              a.update_attribute(:default_tag_id, new_tag.id)
            else
              a.update_attribute(:default_tag_id, nil)
            end
          end
        end
        
        # projects tags
        proj.tag_with(proj.tags_to_s) unless proj.tags_to_s.blank?
        
        # tags of resources
        %w(cases executions requirements test_sets).each do |res|
          proj.send(res).each {|r| r.tag_with(r.tags_to_s) unless r.tags_to_s.blank?}
        end
        
      end
            
      Tag.destroy_all("project_id IS NULL")
      add_index :tags, :name
    end
  end

  def self.down
    remove_column :tags, :project_id
    remove_column :tags, :taggable_type
  end
end
