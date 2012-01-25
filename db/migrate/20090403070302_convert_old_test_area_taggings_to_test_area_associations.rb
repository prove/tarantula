class ConvertOldTestAreaTaggingsToTestAreaAssociations < ActiveRecord::Migration
  def self.up
    Project.all.each do |p|
      p.test_areas.each do |ta|
        ta_tags = Tag.find(:all, 
          :conditions => {:project_id => p.id, :name => ta.name})
        resources = ta_tags.map(&:taggings).flatten.map(&:taggable).compact
        resources.each do |r|
          r.test_areas << ta
        end
        ta_tags.each {|tat| tat.destroy}
      end
    end
  end

  def self.down
  end
end
