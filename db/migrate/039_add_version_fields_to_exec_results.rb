class AddVersionFieldsToExecResults < ActiveRecord::Migration
  def self.up
    add_column :case_executions, :case_version, :integer
    
    start = Time.new
    puts "-- importing version info from :cases"
    CaseExecution.find(:all, :include => :test_case).each{|c|
      begin
        c.update_attribute(:case_version, c.test_case.version)
      rescue
        # Jostain syystä oman kannan kanssa tuli muutamalle
        # executionille virhetilanne, vaikka kanta näytti olevan
        # kunnossa.
        #
        # Siispä tälläinen tyhjä try-catch, jotta homma saadaan ajettua
      end
    }
    puts "   -> #{Time.new - start}s"

    add_column :step_executions, :step_version, :integer

    start = Time.new
    puts "-- importing version info from :steps"
    StepExecution.find(:all, :include => :step).each{|c|
      begin
        c.update_attribute(:step_version, c.step.version)
      rescue
      end
    }
    puts "   -> #{Time.new - start}s"
  end

  def self.down
    remove_column :step_executions, :step_version
    remove_column :case_executions, :case_version
  end
end
