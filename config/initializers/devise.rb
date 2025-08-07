# frozen_string_literal: true

Devise.setup do |config|
  # The secret key used by Devise. Devise uses this key to generate
  # random tokens. Changing this key will render invalid all existing
  # confirmation, reset password and unlock tokens in the database.
  config.secret_key = Rails.application.credentials.devise_secret_key || ENV['DEVISE_SECRET_KEY']

  # ==> Controller configuration
  # Configure the parent class to the devise controllers.
  # config.parent_controller = 'DeviseController'

  # ==> Mailer Configuration
  config.mailer_sender = 'no-reply@haulhub.com'
  
  # ==> ORM configuration
  require 'devise/orm/active_record'

  # ==> Configuration for any authentication mechanism
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]

  # ==> Session configuration
  # Disable session storage for APIs
  config.skip_session_storage = [:http_auth, :token_auth]
  
  # ==> Navigation configuration
  # Disable navigational formats for API-only apps
  config.navigational_formats = []

  # ==> Password configuration
  config.stretches = Rails.env.test? ? 1 : 12
  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  # ==> Recoverable configuration
  config.reset_password_within = 6.hours

  # ==> Rememberable configuration
  config.expire_all_remember_me_on_sign_out = true

  # ==> Validatable configuration
  config.password_length = 6..128

  # ==> JWT configuration
  config.jwt do |jwt|
    jwt.secret = Rails.application.credentials.devise_jwt_secret_key || ENV['DEVISE_JWT_SECRET_KEY']
    jwt.dispatch_requests = [
      ['POST', %r{^/api/v1/auth/sign_in$}],
      ['POST', %r{^/api/v1/auth$}]
    ]
    jwt.revocation_requests = [
      ['DELETE', %r{^/api/v1/auth/sign_out$}]
    ]
    jwt.expiration_time = 1.day.to_i
  end

  # ==> Warden configuration
  config.warden do |manager|
    manager.failure_app = CustomFailureApp
    manager.default_strategies(scope: :user).unshift :jwt_authenticatable
  end

  # ==> Hotwire/Turbo configuration
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other
end
