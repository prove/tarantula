class FixVersionFields < ActiveRecord::Migration
  def self.up
    puts "-- reverts versioned models to the latest versions"

    start = Time.new
    puts "-- reverting :test_sets"
    TestSet.find(:all).each{|s|
      s.revert_to!(s.versions.last)
    }
    puts "   -> #{Time.new - start}s"

    start = Time.new
    puts "-- reverting :cases"
    Case.find(:all).each{|s|
      s.revert_to!(s.versions.last)
    }
    puts "   -> #{Time.new - start}s"

    start = Time.new
    puts "-- reverting :steps"
    Step.find(:all).each{|s|
      s.revert_to!(s.versions.last)
    }
    puts "   -> #{Time.new - start}s"
  end

  def self.down
  end
end
