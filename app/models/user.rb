class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Enums
  enum :user_type, { player: 0, coach: 1, club: 2 }
  enum :role, { user: 0, admin: 1, moderator: 2 }

  # Associations
  has_one :profile, dependent: :destroy
  has_many :user_contacts, dependent: :destroy
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

  # Virtual login attribute to allow email or username
  attr_accessor :login

  # Validations
  validates :phone, presence: true, uniqueness: true, format: { with: /\A[\+]?[0-9\s\-\(\)]+\z/ }
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :username, presence: true,
                       length: { minimum: 4, maximum: 12 },
                       format: { with: /\A[a-z0-9_\-]+\z/ },
                       uniqueness: { case_sensitive: false }
  validates :user_type, presence: true
  validates :first_name, presence: true, length: { maximum: 100 }
  validates :last_name, length: { maximum: 100 }

  # Reserved usernames
  RESERVED_USERNAMES = %w[admin root support api profile profiles user users system help auth login signup register settings me about contact terms privacy].freeze
  validate :username_not_reserved

  # Scopes
  scope :verified, -> { where(verified: true) }
  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(user_type: type) }

  # Callbacks
  before_save { self.email = email.downcase if email.present? }
  before_save { self.username = username.downcase if username.present? }
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

  # Contacts helpers
  def email_contact
    user_contacts.find_by(contact_type: :email, value: email)
  end

  def phone_contact
    user_contacts.find_by(contact_type: :phone, value: phone)
  end

  def email_verified?
    (email_contact&.verified) == true
  end

  def phone_verified?
    (phone_contact&.verified) == true
  end

  def profile_completed?
    profile_completed
  end

  # Devise: support login via username or email
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login_value = conditions.delete(:login)
    if login_value
      where(conditions.to_h).where("LOWER(username) = :value OR LOWER(email) = :value", value: login_value.to_s.downcase).first
    else
      where(conditions.to_h).first
    end
  end

  # Block authentication unless email verified
  def active_for_authentication?
    super && email_verified?
  end

  def inactive_message
    email_verified? ? super : :unverified_email
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

  def username_not_reserved
    return if username.blank?
    errors.add(:username, "is reserved") if RESERVED_USERNAMES.include?(username.downcase)
  end
end
