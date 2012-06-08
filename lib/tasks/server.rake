namespace :server do
  
  
  desc "Start application server in production. Provide PORT."
  task :start => :environment do
    raise "Provide port!" unless ENV['PORT']
    
    pid_file = "#{Rails.root}/tmp/pids/app_server.#{ENV['PORT']}.pid"
    start = "/usr/bin/ruby /usr/bin/mongrel_rails start "+
            "-d -e production -p #{ENV['PORT']} -a 127.0.0.1 -P #{pid_file} "+
            "-c #{Rails.root}"
    
    # borrowed from http://codesnippets.joyent.com/posts/show/931
    if File.exist?(pid_file)
      # mongrels that crash can leave stale PID files behind, and these
      # should not stop mongrel from being restarted by monitors...
      pid = File.new(pid_file).readline
      unless `ps -ef | grep #{pid} | grep -v grep`.length > 0
        File.delete(pid_file)
      end
    end
    
    sh start
  end
  
  desc "Stop application server in production. Provide PORT."
  task :stop => :environment do
    raise "Provide port!" unless ENV['PORT']
    
    stop = "/usr/bin/ruby /usr/bin/mongrel_rails stop -P "+
           "#{Rails.root}/tmp/pids/app_server.#{ENV['PORT']}.pid"
    
    sh stop
  end
  
end
