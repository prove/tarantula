require File.dirname(__FILE__)+'/../test_helper'
require 'performance_test_help'

class CaseTest < ActionController::PerformanceTest
  
  def setup
    @project = Project.make
    @exec = Execution.make(:project => @project)
    @cases = (1..20).map do |i|
      c = Case.make_with_steps(:project => @project)
      5.times do
        CaseExecution.make_with_result(:execution => @exec, :test_case => c)
      end
      c
    end
  end
  
  def test_history
    @cases.map(&:history)
  end
  
end
