class PlayerProfile < Profile
  enum :preferred_foot, { left: 0, right: 1, both: 2 }
  enum :playing_status, { amateur: 0, semi_professional: 1, professional: 2 }
  enum :availability, { available: 0, busy: 1, unavailable: 2 }

  validates :height_cm, numericality: { greater_than: 0, less_than: 300 }, allow_blank: true
  validates :weight_kg, numericality: { greater_than: 0, less_than: 300 }, allow_blank: true

  def achievements_list
    achievements.presence || []
  end

  def training_history_list
    training_history.presence || []
  end
end
