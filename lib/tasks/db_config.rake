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

  end
end
