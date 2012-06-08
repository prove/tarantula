
namespace :db do
  
  desc "Populate database with reference test data."
  task :populate => ['db:populate:simple', 'db:populate:normal', 'db:populate:advanced']
  
  
  namespace :populate do
    
    task :machinist => :environment do
      require 'machinist'
      require File.join(Rails.root, 'spec', 'blueprint')
      require File.join(Rails.root, 'spec', 'blueprint_projects')
      
      # Don't send the new user mails!
      ActionMailer::Base.delivery_method = :test
    end
    
    task :simple => :machinist do
      Project.find_by_name('Simple').try(:destroy)
      Project.make_simple
    end
    
    task :normal => :machinist do
      Project.find_by_name('Normal').try(:destroy)
      Project.make_normal
    end
    
    task :advanced => :machinist do
      Project.find_by_name('Advanced').try(:destroy)
      Project.make_advanced
    end
    
  end
    
end