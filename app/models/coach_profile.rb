class CoachProfile < Profile
  validates :experience_years, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :hourly_rate, numericality: { greater_than: 0 }, allow_blank: true
  validates :currency, inclusion: { in: %w[INR USD EUR] }
  
  def certifications_list
    certifications.presence || []
  end
  
  def coaching_history_list
    coaching_history.presence || []
  end
end