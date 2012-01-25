class RenameBugTrackerSnapshots < ActiveRecord::Migration
  def self.up
    BugTrackerSnapshot.all.each do |bts|
      bts.update_attribute(:name, "2009/#{bts.name.split(' ')[1]}")
    end
  end

  def self.down
  end
end
