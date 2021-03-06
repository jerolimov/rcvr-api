require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RcvrApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0
    config.filter_parameters << :password

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    #
    # Sadly this does not work with rails_admin now.
    config.api_only = false

    config.active_job.queue_adapter = :sidekiq

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*',
          headers: :any,
          expose: ['Authorization'],
          methods: %i[options get post patch]
      end
    end

    # For rails_admin
    config.middleware.use(ActionDispatch::Cookies)
    config.middleware.use(ActionDispatch::Flash)
    config.middleware.use(Rack::MethodOverride)
    config.middleware.use(ActionDispatch::Session::CookieStore, { key: '_rcvr_api_session' })

    config.i18n.available_locales = [:de, :en]
    config.i18n.default_locale = :de
    config.i18n.fallbacks = [:en]

    config.time_zone = 'Berlin'

    # Devise Mailer
    config.to_prepare do
      Devise::Mailer.layout "mailer"
    end
  end
end
