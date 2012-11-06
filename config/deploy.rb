$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require "rvm/capistrano"

set :rvm_ruby_string, '1.9.3'
set :rvm_type, :root # Don't use system-wide RVM
set :rvm_bin_path, "/home/user/.rvm/bin"

set :application, "tarantula"

set :domain, "192.168.24.181"
role :web, domain
role :app, domain
role :db, domain, :primary => true

set :user, "user"
set :deploy_to, "/home/#{user}/#{application}"
set :use_sudo, false

default_run_options[:pty] = true
default_environment['LD_LIBRARY_PATH'] = '/usr/lib/oracle/11.2/client64/lib/'
#default_environment['GEM_PATH'] = '/usr/local/rvm/gems/ruby-1.9.2-p290:/usr/local/rvm/gems/ruby-1.9.2-p290@global'
default_environment['ORACLE_HOME']='/usr/lib/oracle/11.2/client64/'
default_environment['NLS_LANG']='AMERICAN_CIS.UTF8'

set :repository, "git@github.com:evgeniy-khatko/tarantula.git"
set :branch, "master"
set :scm, "git"

set :deploy_via, :copy
set :copy_exclude, []
set :copy_strategy, :export
set :copy_compression, :zip
set :copy_remote_dir, deploy_to

set :bundle_flags, "--quiet"

set :app_port, 80

task :prepare_configs, :roles => :app do
  run "cat #{shared_path}/Gemfile.part >> #{release_path}/Gemfile"
  db_config = File.join shared_path, "database.yml"
  run %Q{ cp #{ db_config } #{ File.join release_path, 'config', 'database.yml' } }
  production_config = File.join shared_path, "production.rb"
  run %Q{ cp #{ production_config } #{ File.join release_path, 'config/environments/production.rb' } }
end

before "bundle:install", :prepare_configs

	namespace :deploy do
	 task(:start) {}
	 task(:stop) {}

	 desc 'Restart Application'
	 task :restart, :roles => :app, :except => { :no_release => true } do
		 run "#{try_sudo} touch #{File.join current_path,'tmp','restart.txt'}"
	 end

	 task :my, :roles => :app do
		 run "echo 1"
	 end
	end
end

