class UserSportAffiliation < ApplicationRecord
  belongs_to :user_sport

  before_validation :clear_end_dates_if_current

  validates :club_team_name, presence: true
  validates :start_year, numericality: { allow_nil: true, greater_than: 1900, less_than_or_equal_to: Date.current.year }
  validates :end_year, numericality: { allow_nil: true, greater_than: 1900, less_than_or_equal_to: Date.current.year }
  validates :start_month, inclusion: { in: 1..12 }, allow_nil: true
  validates :end_month, inclusion: { in: 1..12 }, allow_nil: true

  def pretty_duration
    duration_texts = []
    duration_texts << "#{Date::MONTHNAMES[start_month]}, #{start_year}" if start_year.present? && start_month.present?
    duration_texts << "Present" if current
    duration_texts << "#{Date::MONTHNAMES[end_month]}, #{end_year}" if end_year.present? && end_month.present?
    duration_texts.join(" - ")
  end

  private

  def clear_end_dates_if_current
    return unless ActiveModel::Type::Boolean.new.cast(self.current)
    self.end_month = nil
    self.end_year = nil
  end
end
