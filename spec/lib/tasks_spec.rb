require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "lib/tasks" do
  describe "testia:db" do
    
    before(:all) do
      Rake.application.rake_require "testia_db", 
        [File.join(Rails.root, 'lib', 'tasks')]
    end
    
    it ":check_integrity should make some checks" do
      Rake::Task['testia:db:check_integrity'].execute(nil)
    end
    
    it ":expire_chart_images should call expire! on chart images" do
      i = flexmock('chart image')
      i.should_receive(:expire!).at_least.twice
      flexmock(ChartImage).should_receive(:find).at_least.once.\
        and_return([i, i])
      Rake::Task['testia:db:expire_chart_images'].execute(nil)
    end
    
  end
  
  describe "db" do
    it ":create_views should create necessary views" do
      Rake.application.rake_require "db_create_views", [File.join(Rails.root, 'lib', 'tasks')]
      
      Rake::Task['db:create_views'].execute(nil)
      ActiveRecord::Base.connection.tables.should \
        include('case_avg_duration')
    end
  end
  
end
