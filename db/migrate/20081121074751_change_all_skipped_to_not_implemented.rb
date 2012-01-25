class ChangeAllSkippedToNotImplemented < ActiveRecord::Migration
  def self.up
    ## not used
    remove_column :executions, :result
    
    ActiveRecord::Base.connection.execute(
      %Q(update step_executions set result='NOT_IMPL' where
         result='SKIPPED'))
    
    ActiveRecord::Base.connection.execute(
       %Q(update case_executions set result='NOT_IMPL' where
         result='SKIPPED'))
  end

  def self.down
  end
end
