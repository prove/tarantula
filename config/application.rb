require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Tarantula
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    config.active_record.whitelist_attributes = false

    # Enable the asset pipeline
    config.assets.enabled = true

    config.assets.paths << Rails.root.join("app", "assets", "swf")

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    config.autoload_paths += [config.root.join('lib')]
    config.middleware.use "Authenticator", "Testia"
    config.logger = Logger.new("#{Rails.root}/log/#{Rails.env}.log", 5, 100_000000)
    config.autoload_paths += %W( #{Rails.root}/app/models/core
                                 #{Rails.root}/app/models/report
                                 #{Rails.root}/app/models/report/component
                                 #{Rails.root}/app/models/report/ofc
                                 #{Rails.root}/app/models/import
                                 #{Rails.root}/app/models/bug_tracking
                                 #{Rails.root}/app/models/bug_tracking/jira_integration
                                 #{Rails.root}/app/models/task
                                 #{Rails.root}/app/models/preference
                                 #{Rails.root}/app/models/observers
                                 #{Rails.root}/lib/smart_tag
                                 #{Rails.root}/lib/acts_as_versioned/lib
                                 #{Rails.root}/lib/customerconfig/app/models
                                 )
    config.time_zone = 'Helsinki'

    config.active_record.observers = [:user_observer, :case_execution_observer,
                                      :execution_observer, :tagging_observer]
    config.after_initialize do
      CustomerConfigsController.class_eval do
        before_filter do |c|
          c.require_permission(['ADMIN'])
        end
      end
      ActionMailer::Base.smtp_settings = CustomerConfig.smtp
    end

    ActionMailer::Base.raise_delivery_errors = false
  end
end

######################################################################
# TESTIA CONFIGURATION BEGINS

module Testia
  VERSION = File.read(File.join(Rails.root, 'VERSION')).chomp
end

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
