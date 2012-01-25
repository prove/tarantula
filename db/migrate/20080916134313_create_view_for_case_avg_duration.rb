class CreateViewForCaseAvgDuration < ActiveRecord::Migration
  def self.up
    execute "CREATE VIEW case_avg_duration AS SELECT cases.id AS case_id, "+
      "cases.project_id AS project_id, cases.time_estimate AS time_estimate, "+
      "AVG(case_executions.duration) AS avg_duration FROM cases JOIN "+
      "case_executions ON cases.id = case_executions.case_id GROUP BY case_id"
  end

  def self.down
    execute "DROP VIEW case_avg_duration"
  end
end
