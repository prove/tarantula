namespace :testia do

  desc 'Reset user password. Parameters LOGIN, PW'
  task :reset_password => :environment do
    login = ENV['LOGIN']
    pw = ENV['PW']
    
    u = User.find(:first, :conditions => {:login => login})
    u.password = pw
    u.password_confirmation = pw
    u.save
  end
end
