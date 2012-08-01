# Be sure to restart your server when you modify this file.

Tarantula::Application.config.session_store :cookie_store, key: '_tarantula_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Tarantula::Application.config.session_store :active_record_store
