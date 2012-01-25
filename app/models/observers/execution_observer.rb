=begin rdoc

Case execution observer.

=end
class ExecutionObserver < ActiveRecord::Observer
  
  def before_save(execution)
    return if execution.new_record?
    old_exec = Execution.find(execution.id)
    return if [old_exec.deleted, old_exec.archived, old_exec.test_object_id] \
           == [execution.deleted, execution.archived, execution.test_object_id]
    
    # This expires case's caches which are keyed also by updated_at time
    execution.case_executions.map{|ce| ce.test_case}.each do |tcase|
      next if tcase.nil?
      tcase['updated_at'] = Time.now
      tcase.save_without_revision
    end
  end
  
end
