
namespace :attachment_sets do
  desc "Create a migration for attachment tables, and run it"
  task :create => :environment do
    fname = "create_attachment_tables.rb"
    tstamp = Time.now.strftime("%Y%m%d%H%M%S")
    FileUtils.cp(File.dirname(__FILE__)+"/../lib/#{fname}", 
                 "#{RAILS_ROOT}/db/migrate/#{tstamp}_#{fname}",
                 :verbose => true)
    Rake::Task['db:migrate'].execute(nil)
  end
end
