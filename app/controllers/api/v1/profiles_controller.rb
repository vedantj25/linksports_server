class Api::V1::ProfilesController < Api::V1::BaseController
  before_action :set_profile, only: [ :show, :update, :complete_setup ]
  before_action :ensure_own_profile, only: [ :update, :complete_setup ]

  # GET /api/v1/profiles/:id
  def show
    render_success({ profile: profile_data(@profile) })
  end

  # GET /api/v1/profiles/me
  def me
    profile = current_user.profile
    if profile
      render_success({ profile: profile_data(profile) })
    else
      render_error("Profile not found", :not_found)
    end
  end

  # PATCH /api/v1/profiles/:id
  def update
    if @profile.update(profile_params)
      update_user_sports if params[:sports].present?

      render_success({
        profile: profile_data(@profile.reload)
      }, "Profile updated successfully")
    else
      render_error("Profile update failed", :unprocessable_entity, @profile.errors)
    end
  end

  # PATCH /api/v1/profiles/:id/complete_setup
  def complete_setup
    if @profile.update(profile_params)
      update_user_sports if params[:sports].present?
      @profile.user.update!(profile_completed: true)

      render_success({
        profile: profile_data(@profile.reload)
      }, "Profile setup completed successfully")
    else
      render_error("Profile setup failed", :unprocessable_entity, @profile.errors)
    end
  end

  # POST /api/v1/profiles/:id/upload_image
  def upload_image
    profile = current_user.profile

    if params[:profile_image].present?
      profile.profile_image.attach(params[:profile_image])
      render_success({
        profile_image_url: profile.profile_image.attached? ? url_for(profile.profile_image) : nil
      }, "Profile image uploaded successfully")
    else
      render_error("No image provided", :bad_request)
    end
  end

  # GET /api/v1/profiles/search
  def search
    query = params[:q]
    location = params[:location]
    sport_id = params[:sport_id]
    user_type = params[:user_type]

    profiles = Profile.joins(user: :user_contacts)
                      .where(users: { active: true })
                      .where(user_contacts: { contact_type: UserContact.contact_types[:email], verified: true })

    if query.present?
      profiles = profiles.where(
        "first_name ILIKE ? OR last_name ILIKE ? OR display_name ILIKE ? OR bio ILIKE ?",
        "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%"
      )
    end

    if location.present?
      profiles = profiles.where("location_city ILIKE ? OR location_state ILIKE ?", "%#{location}%", "%#{location}%")
    end

    if sport_id.present?
      profiles = profiles.joins(user: :user_sports).where(user_sports: { sport_id: sport_id })
    end

    if user_type.present?
      profiles = profiles.where(users: { user_type: user_type })
    end

    profiles = profiles.includes(:user, user: [ :user_sports, :sports ])
                      .limit(20)
                      .offset(params[:offset].to_i)

    render_success({
      profiles: profiles.map { |profile| profile_data(profile) },
      total: profiles.count,
      offset: params[:offset].to_i
    })
  end

  private

  def set_profile
    @profile = Profile.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("Profile not found", :not_found)
  end

  def ensure_own_profile
    unless @profile.user == current_user
      render_error("You can only edit your own profile", :forbidden)
    end
  end

  def profile_params
    permitted = [ :first_name, :last_name, :display_name, :bio, :date_of_birth, :gender,
                 :location_city, :location_state, :location_country,
                 :website_url, :instagram_url, :youtube_url ]

    # Add type-specific params
    case @profile.type
    when "PlayerProfile"
      permitted += [ :height_cm, :weight_kg, :preferred_foot, :playing_status, :availability,
                    achievements: [], training_history: [] ]
    when "CoachProfile"
      permitted += [ :experience_years, :hourly_rate, :currency,
                    certifications: [], coaching_history: [] ]
    when "ClubProfile"
      permitted += [ :club_name, :club_type, :establishment_year, :contact_email,
                    facilities: [], programs_offered: [] ]
    end

    params.require(:profile).permit(*permitted)
  end

  def update_user_sports
    # Clear existing sports
    current_user.user_sports.destroy_all

    # Add new sports
    params[:sports].each do |sport_data|
      next if sport_data[:sport_id].blank?

      current_user.user_sports.create!(
        sport_id: sport_data[:sport_id],
        position: sport_data[:position],
        skill_level: sport_data[:skill_level],
        years_experience: sport_data[:years_experience],
        primary: sport_data[:primary] == true || sport_data[:primary] == "1"
      )
    end
  end

  def profile_data(profile)
    data = {
      id: profile.id,
      type: profile.type,
      first_name: profile.first_name,
      last_name: profile.last_name,
      display_name: profile.display_name,
      bio: profile.bio,
      date_of_birth: profile.date_of_birth,
      gender: profile.gender,
      location_city: profile.location_city,
      location_state: profile.location_state,
      location_country: profile.location_country,
      website_url: profile.website_url,
      instagram_url: profile.instagram_url,
      youtube_url: profile.youtube_url,
      profile_image_url: profile.profile_image.attached? ? url_for(profile.profile_image) : nil,
      cover_image_url: profile.cover_image.attached? ? url_for(profile.cover_image) : nil,
      created_at: profile.created_at,
      updated_at: profile.updated_at,
      user: {
        id: profile.user.id,
        user_type: profile.user.user_type,
        email_verified: profile.user.email_verified?,
        profile_completed: profile.user.profile_completed?,
        posts_count: profile.user.posts_count,
        connections_count: profile.user.connections_count
      },
      sports: profile.user.user_sports.includes(:sport).map do |user_sport|
        {
          id: user_sport.id,
          sport: {
            id: user_sport.sport.id,
            name: user_sport.sport.name,
            category: user_sport.sport.category
          },
          position: user_sport.position,
          skill_level: user_sport.skill_level,
          years_experience: user_sport.years_experience,
          primary: user_sport.primary?
        }
      end
    }

    # Add type-specific data
    case profile.type
    when "PlayerProfile"
      data[:player_details] = {
        height_cm: profile.height_cm,
        weight_kg: profile.weight_kg,
        preferred_foot: profile.preferred_foot,
        playing_status: profile.playing_status,
        availability: profile.availability,
        achievements: profile.achievements_list,
        training_history: profile.training_history_list
      }
    when "CoachProfile"
      data[:coach_details] = {
        experience_years: profile.experience_years,
        hourly_rate: profile.hourly_rate,
        currency: profile.currency,
        certifications: profile.certifications_list,
        coaching_history: profile.coaching_history_list
      }
    when "ClubProfile"
      data[:club_details] = {
        club_name: profile.club_name,
        club_type: profile.club_type,
        establishment_year: profile.establishment_year,
        contact_email: profile.contact_email,
        facilities: profile.facilities_list,
        programs_offered: profile.programs_offered_list
      }
    end

    data
  end
end
