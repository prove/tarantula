class CreateTestAreas < ActiveRecord::Migration
  def self.up
    create_table :test_areas do |t|
      t.string :name
      t.integer :project_id
      t.timestamps
    end
    rename_column :project_assignments, :default_tag_id, :test_area_id
    rename_column :project_assignments, :default_tag_forced, :test_area_forced
    
    Project.all.each do |p|
      p.tags.find_all_by_taggable_type('Project').each do |t|
        p.test_areas.create!(:name => t.name)
      end
      p.assignments.each do |pa|
        def_tag = Tag.find_by_id(pa.test_area_id)
        if def_tag
          pa.update_attribute(:test_area, p.test_areas.find_by_name(def_tag.name))
        end
      end
    end
    Project.all.each do |p|
      Tag.destroy_all(:project_id => p.id, :taggable_type => 'Project')
    end
  end

  def self.down
    drop_table :test_areas
    rename_column :project_assignments, :test_area_id, :default_tag_id
    rename_column :project_assignments, :test_area_forced, :default_tag_forced
  end
end
