class SetMissingExecutedAtAndExecutedBy < ActiveRecord::Migration
  def self.up
    ces = CaseExecution.find(
      :all, 
      :conditions => {:result => ['PASSED', 'SKIPPED', 'FAILED'], 
                      :executed_at => nil})
    u = User.find(1)
    ces.each do |ce|
      executor = ce.executed_by || u
      ce.update_attributes!(:executed_at => 3.months.ago,
                            :executed_by => executor)
    end
  end

  def self.down
  end
end
