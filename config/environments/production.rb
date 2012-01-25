# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false

config.action_controller.perform_caching             = false

config.cache_store = :mem_cache_store, '127.0.0.1', {:namespace => "testia_production"}

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host = "http://assets.example.com"


# http://pastie.org/169850
# Use a different logger for distributed setups
ObjectSpace.each_object(Mongrel::HttpServer) { |i| @port = i.port } rescue nil

# Need to be able to run this code during migrations or console
if @port and @port.to_i > 0
  config.logger = Logger.new File.expand_path(RAILS_ROOT+"/log/#{ENV['RAILS_ENV']}.#{@port}.log"), 5, 100.megabytes
else
  puts "Port could not be introspected; we must not be running Mongrel in this instance."
end
