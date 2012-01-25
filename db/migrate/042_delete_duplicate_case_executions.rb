class DeleteDuplicateCaseExecutions < ActiveRecord::Migration
  def self.up
    start = Time.new
    puts "-- deleting duplicate CaseExecutions"

    execs = CaseExecution.find(:all)
    execs.each{|e|
      execs.delete(e)
      execs.each{|c|
        puts "c: #{c.case_id}, #{c.execution_id}"
        puts "e: #{e.case_id}, #{e.execution_id}"
        if ((c.case_id == e.case_id) && (c.execution_id == e.execution_id))
          c.destroy
        end
      }
    }

    puts "   -> #{Time.new - start}s"
  end

  def self.down
  end
end
