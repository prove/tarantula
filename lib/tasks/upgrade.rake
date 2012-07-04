namespace :tarantula do
  desc "Upgrade this Tarantula installation to given version"
  task :upgrade do
    system("cd #{Rails.root}; git pull")
    unless ENV['VERSION'].blank?
      system("git checkout #{ENV['VERSION']}")
    end
    Rake::Task['gems:build:force'].invoke
    Rake::Task[:environment].invoke
    Rake::Task['db:migrate'].invoke
  end
end
