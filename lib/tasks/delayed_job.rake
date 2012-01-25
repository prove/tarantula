namespace :delayed_job do
  
  desc "Install delayed job as a service." 
  task :install => :environment do
    path = File.join(File.dirname(__FILE__), "/../../config/delayed_job")
    FileUtils.cp path, "/etc/init.d/"
    system "/etc/init/delayed_job start"
  end
end
