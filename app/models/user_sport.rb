class UserSport < ApplicationRecord
  belongs_to :user
  belongs_to :sport

  validates :user_id, uniqueness: { scope: :sport_id }
  validates :position, length: { maximum: 100 }
  validates :years_experience, numericality: { greater_than_or_equal_to: 0 }
  validate :details_must_be_hash

  has_many :user_sport_affiliations, dependent: :destroy
  has_many :user_sport_tournaments, dependent: :destroy

  scope :primary, -> { where(primary: true) }

  private

  def details_must_be_hash
    return if details.is_a?(Hash)
    errors.add(:details, "must be a JSON object")
  end
end
