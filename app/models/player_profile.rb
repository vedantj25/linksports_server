class PlayerProfile < Profile
  enum :preferred_foot, { left: 0, right: 1, both: 2 }
  enum :playing_status, { amateur: 0, semi_professional: 1, professional: 2 }
  enum :availability, { available: 0, busy: 1, unavailable: 2 }

  validates :height_cm, numericality: { greater_than: 0, less_than: 300 }, allow_blank: true
  validates :weight_kg, numericality: { greater_than: 0, less_than: 300 }, allow_blank: true
  validate :arrays_lengths_and_content

  def achievement_entries_list
    achievement_entries.presence || []
  end

  # training_history removed per restructuring

  def key_strengths_list
    key_strengths.presence || []
  end

  def fitness_tests_list
    fitness_tests.presence || []
  end

  def academic_education_entries_list
    academic_education_entries.presence || []
  end

  def training_camp_entries_list
    training_camp_entries.presence || []
  end

  private

  def arrays_lengths_and_content
    %i[key_strengths fitness_tests].each do |field|
      values = public_send(field)
      next if values.blank?
      unless values.is_a?(Array)
        errors.add(field, "must be an array of strings")
        next
      end
      if values.size > 100
        errors.add(field, "has too many entries")
      end
      values.each do |v|
        if v.is_a?(String)
          errors.add(field, "entries are too long") if v.length > 255
        else
          errors.add(field, "must contain only strings")
        end
      end
    end
    # Validate structured entries arrays
    { academic_education_entries: academic_education_entries, training_camp_entries: training_camp_entries, achievement_entries: achievement_entries }.each do |field, arr|
      next if arr.blank?
      unless arr.is_a?(Array)
        errors.add(field, "must be a list of objects")
        next
      end
      arr.each do |entry|
        unless entry.is_a?(Hash)
          errors.add(field, "entries must be objects")
          next
        end
        name = entry["name"] || entry[:name]
        year = entry["year"] || entry[:year]
        desc = entry["description"] || entry[:description]
        errors.add(field, "name is required") if name.blank?
        if year.present? && !(year.to_i.between?(1900, 2100))
          errors.add(field, "year must be between 1900 and 2100")
        end
        errors.add(field, "description too long") if desc.present? && desc.to_s.length > 255
      end
    end
  end
end
