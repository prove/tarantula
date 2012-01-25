require File.dirname(__FILE__)+'/../test_helper'
require 'performance_test_help'

class ReportTest < ActionController::PerformanceTest
  
  def test_dashboard
    Project.make_normal
    log_in
    follow_redirect!
  end
  
end
