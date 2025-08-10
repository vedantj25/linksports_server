# Centralized application configuration
# Loaded early by config/application.rb so it is available to environment files

module AppConfig
  module_function

  # Mailer / SMTP
  def smtp_address
    ENV.fetch("SMTP_ADDRESS", "smtp.hostinger.com")
  end

  def smtp_port
    # Default to 587 (STARTTLS) unless explicitly overridden
    Integer(ENV.fetch("SMTP_PORT", 587))
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
    ENV.fetch("MAILER_SENDER", "donotreply@voldebug.in")
  end

  # Twilio (used by phone verification)
  def twilio_account_sid
    ENV.fetch("TWILIO_ACCOUNT_SID", "1234567890")
  end

  def twilio_auth_token
    ENV.fetch("TWILIO_AUTH_TOKEN", "1234567890")
  end

  def twilio_phone_number
    ENV.fetch("TWILIO_PHONE_NUMBER", "+919876543210")
  end
end
