require '../rake_helper'

namespace :db do

  desc "Ask and set application configuration variables & configure servers"
  task :config => ['db:config:app']

  namespace :config do

    desc "Ask and set a single configuration variable in DB."
    task :set => [:environment] do
      key = CC.ask("Give variable name (#{CustomerConfig.all.map(&:name).join(', ')})")
      val = CustomerConfig.send(key)

      if val.is_a?(Hash)
        new_val = {}
        val.each do |k,v|
          new_val[k] = CC.ask("#{key} - #{k}", v)
        end
        CustomerConfig.send("#{key}=", new_val)
      else
        CustomerConfig.send("#{key}=", CC.ask("Value", CustomerConfig.send(key)))
      end
    end

    task :soft => :environment do
      if CustomerConfig.table_exists?
        not_set = CustomerConfig.find(:all, :conditions => {:value => nil})
        unless not_set.empty?
          puts '*'*79
          puts
          puts "WARNING: Following configuration variables have not been set:"
          puts not_set.map(&:name).join(', ')
          puts "Run 'rake db:config' to set them. No restarts required."
          puts
          puts '*'*79
        end
      else
        Rake::Task['db:config'].invoke
      end
    end

  end

end
