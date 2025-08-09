class Profile < ApplicationRecord
  belongs_to :user

  has_one_attached :profile_image
  has_one_attached :cover_image
  has_many :user_sports, through: :user

  validates :first_name, presence: true, length: { maximum: 100 }
  validates :last_name, length: { maximum: 100 }
  validates :bio, length: { maximum: 5000 }
  validates :website_url, :instagram_url, :youtube_url,
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) },
            allow_blank: true
  # Slug removed; profile will be addressed by user's username for sharing

  enum :gender, { male: 0, female: 1, other: 2, prefer_not_to_say: 3 }

  # Slug callbacks removed

  scope :in_city, ->(city) { where(location_city: city) }
  scope :in_state, ->(state) { where(location_state: state) }
  scope :completed, -> { joins(:user).where(users: { profile_completed: true }) }

  def display_name
    read_attribute(:display_name) || "#{first_name} #{last_name}".strip
  end

  def privacy_settings
    super.presence || default_privacy_settings
  end

  # to_param remains default ID; public routes use username on User

  def profile_completed?
    user.profile_completed?
  end

  private

  def default_privacy_settings
    {
      "profile_visibility" => "public",
      "message_permissions" => "connections",
      "show_email" => false,
      "show_phone" => false,
      "show_location" => true
    }
  end

  # Slug generation removed
end
