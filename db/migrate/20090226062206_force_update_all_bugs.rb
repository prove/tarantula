class ForceUpdateAllBugs < ActiveRecord::Migration
  def self.up
    BugTracker.all.each do |bt|
      bt.fetch_bugs(:force_update => true)
    end
  end

  def self.down
  end
end
