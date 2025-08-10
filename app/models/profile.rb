class Profile < ApplicationRecord
  belongs_to :user

  has_one_attached :profile_image
  has_one_attached :cover_image
  has_many_attached :photos
  has_many :user_sports, through: :user

  validates :first_name, presence: true, length: { maximum: 100 }
  validates :last_name, length: { maximum: 100 }
  validates :bio, length: { maximum: 5000 }
  validates :website_url, :instagram_url, :youtube_url,
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) },
            allow_blank: true
  validates :linkedin_url,
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) },
            allow_blank: true

  validate :limit_photos_count
  validate :validate_media_arrays
  before_validation :normalize_media_arrays
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

  def limit_photos_count
    return unless photos.attached?
    if photos.attachments.size > 2
      errors.add(:photos, "cannot have more than 2 images")
    end
  end

  def validate_media_arrays
    { highlight_videos: highlight_videos, media_links: media_links }.each do |field, values|
      next if values.blank?
      unless values.is_a?(Array)
        errors.add(field, "must be an array of URLs")
        next
      end
      values.each do |url|
        unless url.is_a?(String) && url =~ URI::DEFAULT_PARSER.make_regexp(%w[http https])
          errors.add(field, "contains invalid URL")
        end
      end
    end
  end

  def normalize_media_arrays
    if respond_to?(:highlight_videos)
      self.highlight_videos = Array(highlight_videos).map { |u| u.to_s.strip }.reject(&:blank?)
    end
    if respond_to?(:media_links)
      self.media_links = Array(media_links).map { |u| u.to_s.strip }.reject(&:blank?)
    end
  end
end
