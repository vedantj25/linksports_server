class SportAttributeMapping < ApplicationRecord
  belongs_to :sport
  belongs_to :sport_attribute

  validates :sport_id, uniqueness: { scope: :sport_attribute_id }
end
