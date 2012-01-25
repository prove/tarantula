=begin rdoc

Tools for data manipulation.

=end
namespace :testia do
namespace :db do
  
  desc "Check database integrity"
  task :check_integrity => :environment do
    connection = ActiveRecord::Base.connection
    case_ids = connection.select_values(
      "SELECT DISTINCT case_id FROM cases_steps WHERE position IS NULL OR position=0")    
    if case_ids.size > 0
      puts "WARNING: #{case_ids.size} cases which have steps with null or 0 "+
           "positions. Run 'rake testia:db:fix_steps'."
    end
    
    case_exec_ids = connection.select_values(
      "SELECT DISTINCT case_execution_id FROM step_executions WHERE position "+
      "IS NULL OR position=0")
    if case_exec_ids.size > 0
      puts "WARNING: #{case_exec_ids.size} case_executions which have steps "+
           "with null or 0 positions."
    end
    
    case_exec_ids = connection.select_values(
      "SELECT DISTINCT id FROM case_executions WHERE (executed_at "+
      "IS NULL OR executed_by IS NULL) AND RESULT IN ('PASSED','SKIPPED','FAILED')")
    if case_exec_ids.size > 0
      puts "WARNING: #{case_exec_ids.size} case_executions which have executed_at "+
           "or executed_by NULL."
    end
    
    t_count = Tagging.all.select{|t| t.taggable.nil?}.size
    if t_count > 0
      puts "WARNING: #{t_count} invalid taggings."
    end
  end
  
  desc "Remove old chart images"
  task :expire_chart_images => :environment do
    ChartImage.find(:all, 
      :conditions => "created_at < '#{1.hour.ago.to_s(:db)}'").each do |img|
      img.expire!
    end
  end
  
end
end