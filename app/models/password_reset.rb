
require 'digest'

=begin rdoc

A model for resetting User's password.

Fields: link, activated

=end
class PasswordReset < ActiveRecord::Base
  belongs_to :user
  attr_accessor :name_or_email
  
  after_create :create_and_email_link
  before_validation(:on => :create) { find_user }
  validates_presence_of :user_id, :message => 'name or email address not found.'
  validate :allow_reset_only_once_per_day
  
  def activate
    raise "Password already reset!" if self.activated?
    # reset user's password
    self.user.new_random_password
    self.user.save!
    # send password via email
    UserNotifier.new_password(self, self.user.password).deliver
    update_attribute :activated, true
  end
  
  private
  
  def find_user
    self.user = User.find_by_login(name_or_email) || User.find_by_email(name_or_email)
  end
  
  def create_and_email_link
    self.update_attribute(:link,
      Digest::MD5.hexdigest("#{user.name}#{Time.now.to_i}#{rand(10000)}"))
    UserNotifier.password_reset_link(self).deliver
  end
  
  def allow_reset_only_once_per_day
    uid = self.user.try(:id) || 'NULL'
    resets = PasswordReset.find(:all, 
      :conditions => "user_id=#{uid} and created_at >= '#{Date.today-1} 00:00:00'")
    self.errors[:base] << 'Password already reset!' unless resets.empty?
  end
  
end
