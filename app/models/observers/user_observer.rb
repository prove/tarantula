=begin rdoc

User observer.

=end
class UserObserver < ActiveRecord::Observer
  def after_create(user)
    UserNotifier.signup_notification(user).deliver if Rails.env != 'test'
  end
end
