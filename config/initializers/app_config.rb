# Centralized application configuration
# Prefer Rails credentials where applicable, with ENV fallbacks and sensible defaults.

module AppConfig
  module_function

  # Mailer / SMTP
  def smtp_address
    ENV.fetch("SMTP_ADDRESS", "smtp.hostinger.com")
  end

  def smtp_port
    # Default: 465 in development, 587 otherwise
    default_port = Rails.env.development? ? 465 : 587
    Integer(ENV.fetch("SMTP_PORT", default_port))
  end

  def smtp_username
    ENV["SMTP_USERNAME"]
  end

  def smtp_password
    ENV["SMTP_PASSWORD"]
  end

  def smtp_authentication
    # :plain is common for Gmail/most providers
    :plain
  end

  def smtp_enable_starttls_auto
    # true works for both 587 (STARTTLS) and is harmless for 465
    true
  end

  def mailer_sender
    ENV.fetch("MAILER_SENDER", "no-reply@linksports.local")
  end

  # Twilio (used by phone verification)
  def twilio_account_sid
    Rails.application.credentials.dig(:twilio, :account_sid) || ENV["TWILIO_ACCOUNT_SID"]
  end

  def twilio_auth_token
    Rails.application.credentials.dig(:twilio, :auth_token) || ENV["TWILIO_AUTH_TOKEN"]
  end

  def twilio_phone_number
    Rails.application.credentials.dig(:twilio, :phone_number) || ENV["TWILIO_PHONE_NUMBER"]
  end
end


