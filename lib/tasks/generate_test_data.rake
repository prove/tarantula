namespace :testia do

  # Uses Machinist to populate DB
  task :generate_data => :environment do
    require 'machinist'
    require 'spec/blueprint'

    @user = User.first
    @project = Project.first

    10.times do
      TestSet.make_with_cases({:project => @project, :cases => 20, :created_by => @user, :updated_by => @user}, {:created_by => @user, :updated_by => @user})
    end
  end

  task :setup => :environment do

    if ENV['USER_ID']
      user_id = ENV['USER_ID'].to_i
    else
      user_id = 1
    end

    @current_user = User.find(user_id)

    @words = []
    file = File.new(File.join(File.dirname(__FILE__),"en_US.dic"), "r")
    #file = File.new("/rdata/www/testia/en_US.dic", "r")
    #file = File.new("/opt/testia/en_US.dic", "r")

    while (line = file.gets)
      @words << line[/^([^\/]*)/]
    end
    file.close
  end

  desc "Generate cases to project. Settings: COUNT, PROJECT_ID, USER_ID. All settings default to 1."
  task :generate_cases => :setup do

    if ENV['PROJECT_ID']
      project_id = ENV['PROJECT_ID'].to_i
    else
      project_id = 1
    end

    count = ENV['COUNT'].to_i
    if count == 0
      count = 1
    end


    count.times {|i|
      puts "Generating case #{i}"

      # Pad with zeroes to make cases appear in alphabetical order.
      title = "[CASE" + (i+1).to_s.rjust(5,'0') + "] "

      c = Case.create({
        :title => title + random_words(2+rand(5)),
        :project_id => project_id,
        :date => rand(700).days.ago,
        :objective => random_words(10),
        :preconditions_and_assumptions =>  random_words(10),
        :test_data =>  random_words(10),
        :created_by => @current_user.id,
        :updated_by => @current_user.id
      })

      (3 + rand(4)).times {|j|
        c.steps << Step.create({
          :position => j+1,
          :action => random_words(2+rand(5)),
          :result => random_words(2+rand(5))
        })
      }
    }

  end


  desc "Create set and assign cases to it. Settings: COUNT, PROJECT_ID, USER_ID. All settings default to 1."
  task :generate_set => :setup do

    if ENV['PROJECT_ID']
      project_id = ENV['PROJECT_ID'].to_i
    else
      project_id = 1
    end

    count = ENV['COUNT'].to_i
    if count == 0
      count = 1
    end

    tset = TestSet.new({
      :name => random_words(2+rand(5)),
      :project_id => project_id
    })

    cases = Case.find(:all,
      :conditions => ["`title` LIKE '%[CASE%' AND project_id=?", project_id],
      :order => "title", :limit => count)

    raise "No generated cases found." if cases.size == 0

    cases.size.times {|i| cases[i].position = i}
    tset.name = '[SET] '+ '[' + cases.size.to_s + '] ' + tset.name
    tset.save!
    tset.cases << cases
    puts "Created test set #{tset.name} with #{cases.size} cases."
  end

  desc "List users and projects."
  task :info => :setup do

    users = User.find(:all)
    puts "\nUSERS"
    users.map{|c|
      puts "  " + "#{c.id}".ljust(5) + c.login
    }

    projects = Project.find(:all)
    puts "\nPROJECTS"
    projects.map{|c|
      puts "  " + "#{c.id}".ljust(5) + c.name
    }

    puts ""

  end

  def random_words(count)
    name = Array.new(count){|i| @words.rand }.join(' ')
  end

end
