class HomeController < ApplicationController
  
  def index
    if request.xhr? == true
      render :layout => false
    else
      render :layout => "inside"
    end
  end
  
  def login
    if request.post?
      if u = User.authenticate(params[:login], params[:password])
        if !u.latest_project
          flash.now[:notice] = "You have no project assignments."
          return false
        elsif u.deleted?
          flash.now[:notice] = "You have been deleted."
          return false
        else
          session[:user_id] = u.id
          redirect_to :action => 'index'
        end
        return
      end
      session[:user_id] = nil
      flash.now[:notice] = "Login failed."
    end
  end
  
  def logout
    session[:user_id] = nil
    flash[:notice] = "You have been logged out."
    redirect_to :action => 'login'
  end
  
end
