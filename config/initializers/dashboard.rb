require "#{Rails.root}/app/models/dashboard_item"


DashboardItem.new(:overview,
                  'Project Overview', 
                  'Report::ProjectOverview', 
                  nil,
                  Proc.new do |user,project| 
                    pa = user.project_assignments.find_by_project_id(
                              project.id)
                    ta = user.test_area(project)
                    [project.id, (ta ? ta.id : nil), pa.test_object_id]
                  end)

DashboardItem.new(:summary,
                  'Project Summary', 
                  'Report::ProjectSummary', 
                  nil,
                  Proc.new do |user,project| 
                    ta = user.test_area(project)
                    [project.id, (ta ? ta.id : nil)]
                  end)

DashboardItem.new(:results,
                  'Results', 
                  'Report::DashboardResults', 
                  nil,
                  Proc.new do |user,project|
                    pa = user.project_assignments.find_by_project_id(
                              project.id)
                    [project.id, pa.test_object_id, pa.test_area_id]
                  end)

DashboardItem.new(:results_by_to, 
                  'Results by Test Object', 
                  'Report::ResultsByTestObject', 
                  nil,
                  Proc.new do |user,project|
                    to_ids = project.test_objects.ordered.find(
                              :all, :limit => 5).map(&:id)
                    [project.id, to_ids, user.test_area(project), true]
                  end,
                  :new_by_toids)

DashboardItem.new(:bugs, 
                  'Defects', 
                  'Report::BugTrend', 
                  nil,
                  Proc.new do |user,project|
                    ta = user.test_area(project)
                    [project.id, ta.try(:id), :brief]
                  end)

DashboardItem.new(:my_tasks, 
                  'My Tasks', 
                  'Report::MyTasks', 
                  nil,
                  Proc.new{|user,project| [user.id]})

DashboardItem.new(:daily_progress, 
                  'Daily Progress', 
                  'Report::DailyProgress', 
                  nil,
                  Proc.new do |user,project|
                    pa = user.project_assignments.find_by_project_id(
                              project.id)
                    to = pa.test_object_id
                    [project.id, to, pa.test_area_id]
                  end)
