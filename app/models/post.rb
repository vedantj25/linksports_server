class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
  belongs_to :sport, optional: true

  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy

  enum :visibility, { public_post: 0, connections_only: 1, private_post: 2 }

  validates :content, presence: true, length: { maximum: 4000 }
  validates :visibility, presence: true

  scope :publicly_visible, -> { where(visibility: visibilities[:public_post]) }
  scope :by_recent, -> { order(created_at: :desc) }
end
