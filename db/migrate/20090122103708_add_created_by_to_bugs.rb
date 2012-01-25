class AddCreatedByToBugs < ActiveRecord::Migration
  def self.up
    add_column :bugs, :created_by, :integer
    BugTracker.all.each do |bt|
      bt.refresh!
      bt.fetch_bugs(:force_update => true)
    end
  end

  def self.down
    remove_column :bugs, :created_by
  end
end
