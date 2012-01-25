desc 'Removes test data which was generated with "rake generate_test_data".'

task :clear_test_data => :environment do
  User.current_user = User.find(1)
  current_user = User.current_user
  if ((current_user != :false) and current_user.time_zone)
      TzTime.zone = TZInfo::Timezone.get(current_user.time_zone)
  else
      # If time_zone selected by user is nil use default value from 
      # environment.rb.
      TzTime.zone = TZInfo::Timezone.get(ENV['TZ'])
  end

  cases = Case.find(:all, :conditions => "`objective` LIKE 'Automatically generated test data'")
  cases.each{|c|
    c.destroy
  }

  TzTime.reset!
end
