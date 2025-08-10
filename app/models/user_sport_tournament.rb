class UserSportTournament < ApplicationRecord
  belongs_to :user_sport

  validates :tournament_name, presence: true
  validates :year, presence: true,
                   numericality: { only_integer: true, greater_than_or_equal_to: 1900, less_than_or_equal_to: 2100 }
  validates :tournament_name, uniqueness: { scope: [ :user_sport_id, :year ], case_sensitive: false, message: "already added for this year" }
end
