class AddReportedViaTarantulaFieldToBugs < ActiveRecord::Migration
  def self.up
    add_column :bugs, :reported_via_tarantula, :boolean, :default => false
    BugTracker.all.each do |bt|
      bt.fetch_bugs :force_update => true
    end
  end
  
  def self.down
    remove_column :bugs, :reported_via_tarantula
  end
  
end
