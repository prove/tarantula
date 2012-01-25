class AddStatusToBugs < ActiveRecord::Migration
  def self.up
    add_column :bugs, :status, :string
    
    BugTracker.all.each do |bt|
      bt.refresh!
      bt.fetch_bugs(:force_update => true)
    end
  end

  def self.down
    remove_column :bugs, :status
  end
end
