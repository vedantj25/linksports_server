module ProfilesHelper
  def skill_level_color(skill_level)
    case skill_level.to_s
    when "beginner"
      "secondary"
    when "intermediate"
      "warning"
    when "advanced"
      "info"
    when "expert"
      "success"
    else
      "secondary"
    end
  end

  def profile_completion_percentage(profile)
    total_fields = base_profile_fields(profile).count
    completed_fields = base_profile_fields(profile).count { |field| profile.send(field).present? }

    # Add sports completion
    total_fields += 1
    completed_fields += 1 if profile.user.user_sports.any?

    # Add type-specific fields
    case profile.type
    when "PlayerProfile"
      player_fields = [ :height_cm, :weight_kg, :availability ]
      total_fields += player_fields.count
      completed_fields += player_fields.count { |field| profile.send(field).present? }
    when "CoachProfile"
      coach_fields = [ :experience_years, :hourly_rate ]
      total_fields += coach_fields.count
      completed_fields += coach_fields.count { |field| profile.send(field).present? }
    when "ClubProfile"
      club_fields = [ :club_name, :club_type, :establishment_year ]
      total_fields += club_fields.count
      completed_fields += club_fields.count { |field| profile.send(field).present? }
    end

    (completed_fields.to_f / total_fields * 100).round
  end

  def age_from_date_of_birth(date_of_birth)
    return nil unless date_of_birth

    today = Date.current
    age = today.year - date_of_birth.year
    age -= 1 if today < date_of_birth + age.years
    age
  end

  def profile_avatar(profile, size: 120)
    if profile.profile_image.attached?
      image_tag profile.profile_image, class: "rounded-circle", size: "#{size}x#{size}"
    else
      content_tag :div,
                 profile.first_name.first.upcase,
                 class: "avatar-placeholder rounded-circle d-flex align-items-center justify-content-center bg-primary text-white",
                 style: "width: #{size}px; height: #{size}px; font-size: #{size/3}px;"
    end
  end

  private

  def base_profile_fields(profile)
    [ :first_name, :bio, :date_of_birth, :location_city, :location_state ]
  end
end
