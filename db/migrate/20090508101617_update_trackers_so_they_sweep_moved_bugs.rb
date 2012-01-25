class UpdateTrackersSoTheySweepMovedBugs < ActiveRecord::Migration
  def self.up
    BugTracker.all.map do |bt|
      bt.reset_last_fetched 
      bt.fetch_bugs(:force_update => true)
    end
  end

  def self.down
  end
end
