class SetSyncFieldToTrueForOldBugzillas < ActiveRecord::Migration
  def self.up
    Bugzilla.transaction do
      Bugzilla.all.each do |bt|
        bt.update_attributes(:sync_project_with_classification => true)
      end
    end
  end

  def self.down
  end
end
