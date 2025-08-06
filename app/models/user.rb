class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Enums
  enum :user_type, { player: 0, coach: 1, club: 2 }

  # Associations
  has_one :profile, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :events, foreign_key: :creator_id, dependent: :destroy

  # Connections
  has_many :sent_connections, class_name: "Connection", foreign_key: :requester_id, dependent: :destroy
  has_many :received_connections, class_name: "Connection", foreign_key: :addressee_id, dependent: :destroy

  # Messages
  has_many :sent_messages, class_name: "Message", foreign_key: :sender_id, dependent: :destroy
  has_many :received_messages, class_name: "Message", foreign_key: :receiver_id, dependent: :destroy

  # Sports
  has_many :user_sports, dependent: :destroy
  has_many :sports, through: :user_sports

  # Validations
  validates :phone, presence: true, uniqueness: true, format: { with: /\A[\+]?[0-9\s\-\(\)]+\z/ }
  validates :email, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :user_type, presence: true
  validates :first_name, presence: true, length: { maximum: 100 }
  validates :last_name, length: { maximum: 100 }

  # Override Devise email requirement for phone-first auth
  def email_required?
    false
  end

  def email_changed?
    false
  end

  # Scopes
  scope :verified, -> { where(verified: true) }
  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(user_type: type) }

  # Callbacks
  before_save { self.email = email.downcase if email.present? }
  before_save :format_phone_number
  after_create :create_profile

  # Instance methods
  def display_name
    "#{first_name} #{last_name}".strip
  end

  def connected_with?(other_user)
    Connection.between_users(self, other_user)&.connected?
  end

  def connected_user_ids
    Connection.where(
      "(requester_id = ? OR addressee_id = ?) AND status = ?",
      id, id, Connection.statuses[:accepted]
    ).pluck(:requester_id, :addressee_id).flatten.uniq - [ id ]
  end

  def generate_phone_verification_code
    code = rand(100000..999999).to_s
    update!(
      phone_verification_code: code,
      phone_verification_sent_at: Time.current
    )

    # Send SMS using PhoneVerificationService
    PhoneVerificationService.new.send_verification_code(phone)
    code
  end

  def phone_verification_code_valid?(code)
    return false if phone_verification_code.blank?
    return false if phone_verification_sent_at < 10.minutes.ago

    phone_verification_code == code
  end

  def verify_phone!
    update!(
      verified: true,
      phone_verification_code: nil,
      phone_verification_sent_at: nil
    )
  end

  def can_login_with_phone?
    phone.present? && verified?
  end

  def profile_completed?
    profile_completed
  end

  private

  def format_phone_number
    return unless phone.present?

    # Remove all non-digits
    formatted = phone.gsub(/\D/, "")

    # Add country code for India if not present
    formatted = "91#{formatted}" unless formatted.start_with?("91")

    # Add + prefix
    self.phone = "+#{formatted}"
  end

  def create_profile
    profile_attrs = {
      user: self,
      first_name: first_name,
      last_name: last_name
    }

    case user_type
    when "player"
      PlayerProfile.create!(profile_attrs)
    when "coach"
      CoachProfile.create!(profile_attrs)
    when "club"
      ClubProfile.create!(profile_attrs.merge(club_name: display_name))
    end
  end
end
