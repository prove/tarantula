=begin rdoc

Case execution observer.

=end
class CaseExecutionObserver < ActiveRecord::Observer
  
  def after_save(case_exec)
    # This expires case's caches which are keyed also by updated_at time
    tcase = case_exec.test_case
    tcase['updated_at'] = Time.now
    tcase.save_without_revision
  end
  
end
