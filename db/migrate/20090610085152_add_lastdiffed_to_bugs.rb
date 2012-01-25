class AddLastdiffedToBugs < ActiveRecord::Migration
  def self.up
    add_column :bugs, :lastdiffed, :time
    BugTracker.all.map do |bt|
      bt.reset_last_fetched 
      bt.fetch_bugs(:force_update => true)
    end
  end

  def self.down
    remove_column :bugs, :lastdiffed
  end
end
