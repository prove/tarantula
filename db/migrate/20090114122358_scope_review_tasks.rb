class ScopeReviewTasks < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.update "update tasks set type='Review' "+
      "where type='ReviewTask'"
  end

  def self.down
  end
end
