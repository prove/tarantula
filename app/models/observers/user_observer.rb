=begin rdoc

User observer.

=end
class UserObserver < ActiveRecord::Observer
  def after_create(user)
    UserNotifier.deliver_signup_notification(user) if Rails.env != 'test'
  end

  def after_save(user)
    #UserNotifier.deliver_activation(user) if user.recently_activated?
  end
end
