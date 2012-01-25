class MigrateDataToCasesSteps < ActiveRecord::Migration
  
  def self.up
    
    user = User.find(1)
    user.current_user = user 

    steps = Step.find(:all)
    
    steps.each{ |s|
      
      if not s[:case_id]
        puts "Step case id is null! Deleting: " + 
          "#{s[:id]} #{s[:action]} #{s[:result]}"
        next
      end
      
      tcase = Case.find( s[:case_id])

      cs = CasesSteps.new
      cs[:case_id] = s[:case_id]
      cs[:case_version] = tcase[:version]
      cs[:position] = s[:order]
      cs[:step_id] = s[:id]
      cs[:step_version] = s[:version]
      
      cs.save!
    }
   
  end
    
  def self.down
  end
end
