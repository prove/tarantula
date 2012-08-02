# Load classes for Delayed Job
Report::Dashboard
Report::ProjectOverview
Report::ProjectSummary
Report::DashboardResults
Report::ResultsByTestObject
Report::BugTrend
Report::MyTasks
Report::DailyProgress

# Delayed::Worker.destroy_failed_jobs = false
# Delayed::Worker.sleep_delay = 60
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 5.minutes
# Delayed::Worker.read_ahead = 10
# Delayed::Worker.delay_jobs = !Rails.env.test?
