require File.join(Rails.root, 'lib/customerconfig/rake_helper')

namespace :db do
  namespace :config do

    task :app => [:environment] do
      puts "\nGENERAL"
      CC.ask_host_info
      CustomerConfig.admin_email = CC.ask("Admin Email", CustomerConfig.admin_email)

      puts "\nSMTP"
      CC.ask_smtp_info

      puts "\nDone."
    end

    desc "Setup configuration non-interactively from environment vars"
    task :fromenv => [:environment] do
      CustomerConfig.protocol = ENV['PROTO'] || 'https'
      CustomerConfig.host = ENV['HOST']

      # This email will be used as Admin user's mail address
      CustomerConfig.admin_email = ENV['EMAIL']
      # This will be from address in automatic notifications
      CustomerConfig.notification_email = ENV['NOTIFEMAIL']

      CustomerConfig.smtp = {
        :address => 'localhost',
        :port => '25',
        :domain => ENV['MAILDOMAIN']
      }
    end

  end
end
