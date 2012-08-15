### CUSTOMER SPECIFIC SETTINGS (from environment.rb) ###

# SMTP Settings.
# Needed for automatic notifications (user logins and passwords
# are sent by email).

module Testia
  # SERVER ROOT URL.
  # This is used in notifications sent by server to new user
  # accounts (where application is available to users).
  port = CustomerConfig.port.blank? ? '' : ":#{CustomerConfig.port}"
  WWW_SERVER="#{CustomerConfig.protocol}://#{CustomerConfig.host}#{port}"

  # Set email address which is used as from address for automatic
  # notifications.  Try to use notification_email setting from
  # customer_configs table and fallback to admin_email setting.
  ADMIN_EMAIL = CustomerConfig.notification_email || CustomerConfig.admin_email

  # How many items to load at once at tagged lists.
  # No need to change this.
  LOAD_LIMIT = 500

  DEFAULT_REPORT_CACHE_TIME = 1.minute
end
