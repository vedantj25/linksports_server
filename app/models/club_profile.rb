class ClubProfile < Profile
  enum :club_type, { academy: 0, club: 1, training_center: 2, school: 3 }
  
  validates :club_name, presence: true, length: { maximum: 200 }
  validates :establishment_year, numericality: { 
    greater_than: 1800, 
    less_than_or_equal_to: Date.current.year 
  }, allow_blank: true
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  
  def facilities_list
    facilities.presence || []
  end
  
  def programs_offered_list
    programs_offered.presence || []
  end
end