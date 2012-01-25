=begin rdoc

A mail notifier for (new) users.

=end
class UserNotifier < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += 'Account created'
  end
  
  def password_reset_link(password_reset)
    @recipients  = password_reset.user.email
    @from        = Testia::ADMIN_EMAIL
    @subject     = "[Testia] Password reset link"
    @sent_on     = Time.now
    @body[:password_reset] = password_reset
  end
  
  def new_password(password_reset, new_password)
    @recipients  = password_reset.user.email
    @from        = Testia::ADMIN_EMAIL
    @subject     = "[Testia] Your password has been reset"
    @sent_on     = Time.now
    @body[:password_reset] = password_reset
    @body[:new_password] = new_password
  end
  
  protected
  
  def setup_email(user)
    @recipients  = user.email
    @from        = Testia::ADMIN_EMAIL
    @subject     = "[Testia] "
    @sent_on     = Time.now
    @body[:user] = user
  end
end
