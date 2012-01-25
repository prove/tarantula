# Be sure to restart your web server when you modify this file.

SCRIPT_LINES__ = {} if ENV['RAILS_ENV'] == 'development'

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.3' unless defined? RAILS_GEM_VERSION

# Default configurations for different Bug Trackers. These values are used
# to determine how different issue statuses etc should be interpretet in reports
# and other requests.
#
# These can be customized by adding CustomerConfig values using
# format: bt-type_value_name eg. 'jira_open_statuses' for the customer
# config name.
BT_CONFIG = {
  :jira => {
    :defect_types => ['Bug'],
    :open_statuses => ['Open', 'In Progress', 'Reopened'],
    :fixed_statuses => ['Resolved'],
    :verified_statuses => ['Closed'],
    :closed_statuses => ['Closed'],
    :encoding => 'utf8',
    :severities => {
      :not_relevant => '#AAAA00',
      :works_as_designed => '#339933'
    }
  },
  :bugzilla => {
    :open_statuses => ['NEW', 'ASSIGNED', 'REOPENED'],
    :fixed_statuses => ['RESOLVED'],
    :verified_statuses => ['VERIFIED'],
    :closed_statuses => ['CLOSED']
  }
}

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.middleware.use "Authenticator", "Testia"

  config.logger = Logger.new("#{RAILS_ROOT}/log/#{RAILS_ENV}.log", 5, 100.megabyte)
  # Settings in config/environments/* take precedence over those specified here

  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Only load the plugins named here, by default all plugins in
  # vendor/plugins are loaded
  # config.plugins = %W( exception_notification ssl_requirement )

  # Add additional load paths for your own custom dirs
  config.load_paths += %W( #{RAILS_ROOT}/app/models/core
                           #{RAILS_ROOT}/app/models/report
                           #{RAILS_ROOT}/app/models/report/component
                           #{RAILS_ROOT}/app/models/report/ofc
                           #{RAILS_ROOT}/app/models/import
                           #{RAILS_ROOT}/app/models/bug_tracking
                           #{RAILS_ROOT}/app/models/bug_tracking/jira_integration
                           #{RAILS_ROOT}/app/models/task
                           #{RAILS_ROOT}/app/models/preference
                           #{RAILS_ROOT}/app/models/observers
                           #{RAILS_ROOT}/lib/smart_tag )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the
  # test database.  This is necessary if your schema can't be
  # completely dumped by the schema dumper, like if you have
  # constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time

  config.time_zone = 'Helsinki'

  # See Rails::Configuration for more options
  config.action_controller.session = {
    :key => "testia_premo_session_id",
    :secret => "xxxx1.1 release phrasesome secret phrasesome secret" +
               "phrasesome secret phrasesome secret phrasesome secret" +
               "phrasesome secret phrase"
    }
  config.active_record.observers = [:user_observer, :case_execution_observer, :execution_observer, :tagging_observer]

  # Make configuration interface available only to ADMIN user
  config.after_initialize do
    CustomerConfigsController.class_eval do
      before_filter do |c|
        c.require_permission(['ADMIN'])
      end
    end
  end

end

ActionMailer::Base.smtp_settings = CustomerConfig.smtp
ActionMailer::Base.raise_delivery_errors = false

ActiveRecord::Base.logger.level = Logger::INFO if RAILS_ENV == 'production'

######################################################################
# TESTIA CONFIGURATION BEGINS

module Testia
  VERSION = File.read(File.join(RAILS_ROOT, 'VERSION')).chomp
end

#
# TESTIA CONFIGURATION ENDS.
######################################################################
