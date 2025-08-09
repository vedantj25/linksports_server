class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post, counter_cache: true

  validates :content, presence: true, length: { maximum: 1000 }
end
