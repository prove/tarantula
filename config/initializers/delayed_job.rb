# Load classes for Delayed Job
Report::Dashboard
Report::ProjectOverview
Report::ProjectSummary
Report::DashboardResults
Report::ResultsByTestObject
Report::BugTrend
Report::MyTasks
Report::DailyProgress

# config/initializers/delayed_job_config.rb
# Delayed::Job.destroy_failed_jobs = false
silence_warnings do
  Delayed::Job.const_set("MAX_ATTEMPTS", 3)
  Delayed::Job.const_set("MAX_RUN_TIME", 5.minutes)
end
