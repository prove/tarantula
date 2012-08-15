class PasswordResetsController < ApplicationController
  skip_before_filter :set_current_user_and_project
  
  # GET /password_resets/1
  # GET /password_resets/1.xml
  def show
    password_reset = PasswordReset.find_by_link(params[:id])
    txt = "New password has been sent to you."
    if password_reset.nil?
      render :nothing => true
      return
    end
    
    begin
      password_reset.activate
    rescue Exception => e
      txt = e.message
    end
    render :text => txt, :status => :ok
  end

  # POST /password_resets
  def create
    pr = PasswordReset.create(:name_or_email => params[:name_or_email])
    
    if pr.errors.empty?
      render :js => "Element.replace('forgot', 'You have been sent a link to reset your password.'); Element.replace('forgot_link', '');"
    else
      render :js => "Element.update('errors', '"+pr.errors.full_messages.join(', ')+"');"
    end
  end

end
