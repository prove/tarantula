namespace :tarantula do

  def retrieve_db_info
    result = File.read "#{Rails.root}/config/database.yml"
    result.strip!
    config_file = YAML::load(ERB.new(result).result)
    return [
      config_file[Rails.env]['database'],
      config_file[Rails.env]['username'],
      config_file[Rails.env]['password'],
      config_file[Rails.env]['host']
    ]
  end

def check_if_database_exists 
    database, user, password, host = retrieve_db_info
    
    cmd = "mysql -u #{user} -h #{host} "
    puts cmd + "... [password filtered]"
    cmd += " -p'#{password}'" unless password.nil?
    cmd += " testia"
    cmd += " -e 'show tables like \"users\"'"
    output = system cmd
    output = output.to_s
    return output
end

  desc "Initialize and install new Tarantula instance"
    if check_if_database_exists === "false"
      task :install => ['db:setup', 'delayed_job:install', 'assets:precompile', :environment] do
        Rake::Task['db:config:app'].invoke
        # Prompt about initial data and generate if needed
        Rake::Task['tarantula:init_db'].execute
        # Create db views
        Rake::Task['db:create_views'].execute
        puts "Initialization tasks done. Please restart your web server services. Eg. apache, memcached etc"
      end
    else 
      task :install => [] do
        puts "Testia database already installed, nothing to do."
      end
    end
end
