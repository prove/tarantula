class FixUnversioned < ActiveRecord::Migration
  def self.up
    
    user = User.find(1)
    user.current_user = user 
    
    # Make sure that at least one versioned entry exists for
    
    # Cases
    
    puts "FIXING CASES"
    puts "====================================="
    cases = Case.find(:all)
    
    cases.each{ |c|
      puts "#{c.id}.#{c.title} v #{c.version}"
      
      version = Case.find_version( c.id, c.version)
      
      if not version
        puts "Version not available, saving version."
        c.save!
      end
      puts "\n\n"
    }

    
    # Steps
    
    puts "FIXING STEPS"
    puts "====================================="
    steps = Step.find(:all)
    
    steps.each{ |c|
      puts "#{c.id}.#{c.action} v #{c.version}"
      
      version = Step.find_version( c.id, c.version)
      
      if not version
        puts "Version not available, saving version."
        c.save!
      end
      puts "\n\n"
    }
    
    # Test Sets
    
    puts "FIXING TEST SETS"
    puts "====================================="
    sets = TestSet.find(:all)
    
    sets.each{ |c|
      puts "#{c.id}.#{c.name} v #{c.version}"
      
      version = TestSet.find_version( c.id, c.version)
      
      if not version
        puts "Version not available, saving version."
        c.save!
      end
      puts "\n\n"
    }
    
    
    
    puts "FIXING CASE EXECUTIONS"
    puts "====================================="
    
    ces = CaseExecution.find(:all)

    ces.each{ |ce|
      puts "\n\n"
      puts "Checking case execution ##{ce.id}"

      

      c = ce.test_case
      
      if c == nil
        puts "\n\n\n"
        puts "ALERT ----------------"
        puts " Test case not found!"
        puts ce.attributes.to_json
        puts ""
        puts "ALERT ----------------\n\n\n"        
        next
      end
      
            
      case_version = ce.case_version
      
      if not case_version
        puts "Version is null, defaulting to 1"
        case_version = 1
        ce.case_version = case_version
        ce.save!
      end
            
      if not c.revert_to(case_version)
        puts " Unable to find versioned test case for: " +
          "#{c.title} version #{case_version}"
        
        #Try next version
        case_version += 1
        if not c.revert_to(case_version)
          
          puts "\n\n\n"
          puts "ALERT ----------------"
          puts " Unable to find version #{case_version} either."
          puts "ALERT ----------------\n\n\n"
        else
          puts "Later version #{case_version} found! " +
            "Will be used by execution."
          ce.case_version = case_version
          ce.save!
        end
        
      end
      
    }
  end
    
  def self.down
  end
end
