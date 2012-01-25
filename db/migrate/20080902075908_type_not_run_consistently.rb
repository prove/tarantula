class TypeNotRunConsistently < ActiveRecord::Migration
  def self.up
    execute "UPDATE case_executions SET result='NOT_RUN' WHERE result='NOT RUN'"
  end

  def self.down
    # no need to do changes here
  end
end
