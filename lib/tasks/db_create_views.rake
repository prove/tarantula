
namespace :db do
  
  desc "Recreate views"
  task :create_views => :environment do
    c = ActiveRecord::Base.connection
    c.execute "DROP TABLE IF EXISTS case_avg_duration"
    c.execute "DROP VIEW IF EXISTS case_avg_duration"
    c.execute "CREATE VIEW case_avg_duration AS SELECT cases.id AS case_id, "+
          "cases.project_id AS project_id, cases.time_estimate AS time_estimate, "+
          "AVG(case_executions.duration) AS avg_duration FROM cases JOIN "+
          "case_executions ON cases.id = case_executions.case_id "+
          "WHERE case_executions.duration > 0 GROUP BY case_id"
  end
  
end