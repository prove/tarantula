namespace :tarantula do
  desc "Initialize and install new Tarantula instance"
  task :install => ['db:setup', 'delayed_job:install', 'assets:precompile', :environment] do
    Rake::Task['db:config:app'].invoke
    # Prompt about initial data and generate if needed
    Rake::Task['tarantula:init_db'].execute
    # Create db views
    Rake::Task['db:create_views'].execute
    puts "Initialization tasks done. Please restart your web server services. Eg. apache, memcached etc"
  end
end
