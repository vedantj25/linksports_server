require "twilio-ruby"
require "ostruct"

class PhoneVerificationService
  def initialize
    @account_sid = Rails.application.credentials.dig(:twilio, :account_sid) || ENV["TWILIO_ACCOUNT_SID"]
    @auth_token = Rails.application.credentials.dig(:twilio, :auth_token) || ENV["TWILIO_AUTH_TOKEN"]
    @phone_number = Rails.application.credentials.dig(:twilio, :phone_number) || ENV["TWILIO_PHONE_NUMBER"]

    @client = Twilio::REST::Client.new(@account_sid, @auth_token)
  end

  def send_verification_code(phone_number)
    # Generate 6-digit verification code
    verification_code = sprintf("%06d", SecureRandom.random_number(1000000))

    # For development, we'll just log the code instead of sending SMS
    if Rails.env.development?
      Rails.logger.info "📱 SMS Verification Code for #{phone_number}: #{verification_code}"
      return OpenStruct.new(success?: true, verification_code: verification_code)
    end

    # In production, send actual SMS
    begin
      message = @client.messages.create(
        from: @phone_number,
        to: format_phone_number(phone_number),
        body: "Your LinkSports verification code is: #{verification_code}. This code will expire in 10 minutes."
      )

      if message.sid
        OpenStruct.new(success?: true, verification_code: verification_code)
      else
        Rails.logger.error "Twilio SMS failed: #{message.error_message}"
        OpenStruct.new(success?: false, error: message.error_message)
      end
    rescue => e
      Rails.logger.error "Twilio SMS error: #{e.message}"
      OpenStruct.new(success?: false, error: e.message)
    end
  end

  def verify_code(user, provided_code)
    return false if user.phone_verification_code.blank?
    return false if user.phone_verification_sent_at.blank?
    return false if user.phone_verification_sent_at < 10.minutes.ago

    user.phone_verification_code == provided_code.to_s
  end

  private

  def format_phone_number(phone)
    # Add country code for India if not present
    formatted = phone.gsub(/\D/, "") # Remove all non-digits
    formatted = "+91#{formatted}" unless formatted.start_with?("+91")
    formatted
  end
end
