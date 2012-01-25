class MarkOldTarantulaReportedBugsAsTarantulaReported < ActiveRecord::Migration
  def self.up
    BugTracker.all.each do |bt|
      bt.bugs.each do |bug|
        desc = bt.instance_eval{ get_longdesc(bug.external_id) }
        if desc =~ /OBJECTIVE(.*)TEST DATA(.*)PRECONDITIONS AND ASSUMPTIONS/m
          bug.update_attribute :reported_via_tarantula, true
        end
      end
    end
  end

  def self.down
  end
end
