class HomeController < ApplicationController
  
  def index
    if request.xhr? == true
      render :layout => false
    else
      render :layout => "inside"
    end
  end
  
  def login
    if request.post? and can_do_stuff?(params[:login],params[:password])
			redirect_to :action => 'index'
    end
  end
  
  def logout
    session[:user_id] = nil
    flash[:notice] = "You have been logged out."
    redirect_to :action => 'login'
  end
  
end
