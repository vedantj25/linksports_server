class Sport < ApplicationRecord
  has_many :user_sports, dependent: :destroy
  has_many :users, through: :user_sports
  has_many :posts, dependent: :nullify
  has_many :events, dependent: :nullify
  has_many :sport_attribute_mappings, dependent: :destroy
  has_many :sport_attributes, through: :sport_attribute_mappings

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :category, presence: true

  scope :active, -> { where(active: true) }
  scope :by_category, ->(category) { where(category: category) }

  before_save { self.name = name.titleize }
end
