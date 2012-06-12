=begin rdoc

A mail notifier for (new) users.

=end
class UserNotifier < ActionMailer::Base
  default :from => Testia::ADMIN_EMAIL
  
  def signup_notification(user)
    @account = @user = user
    @subject         = "[Tarantula] Account created"
    mail(:to => @account.email, :subject => @subject)
  end
  
  def password_reset_link(password_reset)
    @account        = password_reset.user
    @subject        = "[Tarantula] Password reset link"
    @password_reset = password_reset
    mail(:to => @account.email, :subject => @subject)
  end
  
  def new_password(password_reset, new_password)
    @account        = password_reset.user
    @subject        = "[Tarantula] Your password has been reset"
    @password_reset = password_reset
    @new_password   = new_password
    mail(:to => @account.email, :subject => @subject)
  end
  
end
