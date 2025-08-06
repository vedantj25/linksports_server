class UserSport < ApplicationRecord
  belongs_to :user
  belongs_to :sport
  
  enum :skill_level, { beginner: 0, intermediate: 1, advanced: 2, expert: 3 }
  
  validates :user_id, uniqueness: { scope: :sport_id }
  validates :position, length: { maximum: 100 }
  validates :years_experience, numericality: { greater_than_or_equal_to: 0 }
  validates :skill_level, presence: true
  
  scope :primary, -> { where(primary: true) }
  scope :by_skill_level, ->(level) { where(skill_level: level) }
end
