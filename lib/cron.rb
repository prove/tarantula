require 'rake'

=begin rdoc

Call Cron modules methods in cron tab, for example:
0 0	* 	* 	*		 /Rails.root/script/runner -e production "Cron.daily"

=end
module Cron
  
  def self.every_15_min
    # update all bug trackers
    BugTracker.all.each do |bt|
      bt.fetch_bugs
    end
  end
  
  def self.daily
    # delete old chart images
    ChartImage.find(:all, 
      :conditions => "created_at < '#{1.hour.ago.to_s(:db)}'").each do |img|
      img.expire!
    end
    
    # delete old report post data
    Report::Data.destroy_all("created_at < '#{1.hour.ago.to_s(:db)}'")
    
    # dump db
    Rake.application.rake_require "db_backup", 
                                  [File.join(Rails.root, 'lib', 'tasks')]
    Rake::Task['db:backup'].execute(nil)
  end
  
  def self.weekly
    BugTracker.all.each do |bt|
      bt.take_snapshot("Week #{Date.today.year}/#{Date.today.cweek.to_s.rjust(2,'0')}")
    end
  end
  
end