require File.dirname(__FILE__)+'/../test_helper'
require 'performance_test_help'

class HomeTest < ActionController::PerformanceTest
  
  def test_login_get
    get '/home/login'
  end
  
  def test_login_post
    @project = Project.make_simple
    @user = Admin.make
    post '/home/login', {:login => @user.login, :password => @user.password}
  end
  
end
