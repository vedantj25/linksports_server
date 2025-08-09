class UserContact < ApplicationRecord
  belongs_to :user

  enum :contact_type, { email: 0, phone: 1 }

  before_validation :normalize_value

  validates :value, presence: true
  validates :contact_type, presence: true
  validates :value, uniqueness: { scope: :contact_type, case_sensitive: false }

  # OTP settings
  OTP_EXPIRY_MINUTES = 10
  MAX_ATTEMPTS = 5
  RESEND_COOLDOWN_SECONDS = 60
  DAILY_LIMIT = 10

  def generate_and_send_otp
    raise "Daily limit reached" if daily_limit_reached?
    raise "Please wait before requesting another code" if resend_cooldown_active?

    code = format("%06d", SecureRandom.random_number(1_000_000))
    update!(
      verification_code: code,
      verification_sent_at: Time.current,
      last_sent_at: Time.current,
      daily_send_count: daily_send_count_for_today + 1
    )

    if email?
      UserContactMailer.with(contact: self).verification_code_email.deliver_later
    elsif phone?
      # placeholder for future SMS send
    end

    code
  end

  def verify_code!(provided_code)
    raise "Too many attempts" if verification_attempts >= MAX_ATTEMPTS
    increment!(:verification_attempts)

    if code_valid?(provided_code)
      update!(verified: true, verification_code: nil, verification_sent_at: nil, verification_attempts: 0)
      true
    else
      false
    end
  end

  def code_valid?(provided_code)
    return false if verification_code.blank?
    return false if verification_sent_at.blank?
    return false if verification_sent_at < OTP_EXPIRY_MINUTES.minutes.ago
    ActiveSupport::SecurityUtils.secure_compare(verification_code.to_s, provided_code.to_s)
  end

  def resend_cooldown_active?
    last_sent_at.present? && last_sent_at > RESEND_COOLDOWN_SECONDS.seconds.ago
  end

  def daily_limit_reached?
    daily_send_count_for_today >= DAILY_LIMIT
  end

  def daily_send_count_for_today
    return 0 if last_sent_at.blank? || last_sent_at.to_date != Date.current
    daily_send_count
  end

  private

  def normalize_value
    case contact_type.to_sym
    when :email
      self.value = value.to_s.strip.downcase
    when :phone
      self.value = normalize_phone(value)
    end
  end

  def normalize_phone(phone)
    return "" if phone.blank?
    digits = phone.gsub(/\D/, "")
    digits = "91#{digits}" unless digits.start_with?("91")
    "+#{digits}"
  end
end
