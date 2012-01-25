class TagAllTestObjectsToAllTestAreas < ActiveRecord::Migration
  def self.up
    Project.all.each do |proj|
      tag_string = proj.test_areas.map(&:name).join(',')
      proj.test_objects.each {|to| to.tag_with(tag_string)}
    end
  end

  def self.down
  end
end
