class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile, only: [ :show, :edit, :update, :public_view, :complete_setup ]
  before_action :ensure_own_profile, only: [ :edit, :update, :complete_setup ]

  # GET /profiles/:id
  def show
    redirect_to public_profile_path(username: @profile.user.username)
  end

  # GET /profiles/:id/public_view
  def public_view
    @user = @profile.user
    @user_sports = @profile.user.user_sports.includes(:user_sport_affiliations, :user_sport_tournaments, sport: :sport_attributes)
    @is_own_profile = @profile.user == current_user
  end

  # GET /profiles/:id/edit
  def edit
    @sports = Sport.active.order(:name).includes(:sport_attributes)
    @user_sports = @profile.user.user_sports.includes(:sport)
  end

  # PATCH /profiles/:id
  def update
    if @profile.update(profile_params)
      update_user_sports if params[:sports].present?
      # Auto-complete setup if criteria met
      if !@profile.user.profile_completed? && profile_complete?(@profile)
        @profile.user.update!(profile_completed: true)
      end
      redirect_to profile_path(@profile), notice: "Profile updated successfully!"
    else
      @sports = Sport.active.order(:name)
      @user_sports = @profile.user.user_sports.includes(:sport)
      render :edit, status: :unprocessable_entity
    end
  end

  # GET /profiles/new
  def new
    # Redirect to edit if profile already exists
    if current_user.profile.present?
      redirect_to edit_profile_path(current_user.profile)
      return
    end

    # This shouldn't normally happen as profiles are auto-created
    redirect_to root_path, alert: "Profile creation error. Please contact support."
  end

  # POST /profiles (not used - profiles auto-created with user)
  def create
    redirect_to edit_profile_path(current_user.profile)
  end

  # PATCH /profiles/:id/complete_setup
  def complete_setup
    if @profile.update(profile_params)
      update_user_sports if params[:sports].present?
      @profile.user.update!(profile_completed: true)
      redirect_to profile_path(@profile), notice: "Welcome to LinkSports! Your profile is now complete."
    else
      @sports = Sport.active.order(:name)
      @user_sports = @profile.user.user_sports.includes(:sport)
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_profile
    # access profiles by ID within app; public sharing uses /profile/:username
    @profile = Profile.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Profile not found."
  end

  def ensure_own_profile
    unless @profile.user == current_user
      redirect_to profile_path(@profile), alert: "You can only edit your own profile."
    end
  end

  def profile_complete?(profile)
    profile_completion_percentage(profile) >= 100
  end

  def profile_params
    # Use polymorphic parameter names based on profile type
    param_key = case @profile.type
    when "PlayerProfile"
                  :player_profile
    when "CoachProfile"
                  :coach_profile
    when "ClubProfile"
                  :club_profile
    else
                  :profile
    end

    # Merge type-specific params with generic `profile` params so shared fields
    # like media arrays work regardless of the param namespace
    typed_params = params[param_key] || ActionController::Parameters.new
    generic_params = params[:profile] || ActionController::Parameters.new
    profile_params = ActionController::Parameters.new(
      typed_params.to_unsafe_h.merge(generic_params.to_unsafe_h)
    )

    # Base permitted params
    permitted = [ :first_name, :last_name, :display_name, :bio, :date_of_birth, :gender,
                 :location_city, :location_state, :location_country,
                 :website_url, :instagram_url, :youtube_url, :linkedin_url,
                 :profile_image, photos: [], highlight_videos: [], media_links: [] ]

    # Add type-specific params
    case @profile.type
    when "PlayerProfile"
      permitted += [ :height_cm, :weight_kg, :preferred_foot, :availability,
                    achievement_entries: [ :name, :year, :description ],
                    key_strengths: [], fitness_tests: [],
                    academic_education_entries: [ :name, :year, :description ],
                    training_camp_entries: [ :name, :year, :description ] ]
    when "CoachProfile"
      permitted += [ :experience_years, :hourly_rate, :currency,
                    certifications: [], coaching_history: [] ]
    when "ClubProfile"
      permitted += [ :club_name, :club_type, :establishment_year, :contact_email,
                    facilities: [], programs_offered: [] ]
    end

    profile_params.permit(*permitted)
  end

  def update_user_sports
    # Clear existing sports
    current_user.user_sports.destroy_all

    # Normalize incoming sports params to an array of attribute hashes
    sports_param = params[:sports]
    sport_entries = if sports_param.is_a?(ActionController::Parameters) || sports_param.is_a?(Hash)
                      sports_param.values
    else
                      sports_param
    end

    Array(sport_entries).each do |entry|
      attributes = case entry
      when ActionController::Parameters then entry.to_unsafe_h
      when Hash then entry
      else {}
      end

      next if attributes["sport_id"].blank?

      user_sport = current_user.user_sports.create!(
        sport_id: attributes["sport_id"],
        position: attributes["position"],
        years_experience: attributes["years_experience"],
        primary: attributes["primary"].to_s == "1",
        details: attributes["details"] || {}
      )

      # Inline affiliations (supports both array and indexed-hash formats)
      aff_param = attributes["affiliations"] || attributes[:affiliations]
      aff_collection =
        if aff_param.is_a?(Hash)
          aff_param.values
        else
          Array(aff_param)
        end
      aff_collection.each do |aff|
        next unless aff.is_a?(Hash) || aff.is_a?(ActionController::Parameters)
        aff = aff.to_unsafe_h if aff.is_a?(ActionController::Parameters)
        next if aff["club_team_name"].blank?
        # Rails may submit both hidden "0" and checkbox "1". Handle string/boolean/array robustly.
        current_values = Array(aff["current"]) # => ["0", "1"] or ["0"] or ["1"] or [true]
        current_flag = current_values.any? { |v| ActiveModel::Type::Boolean.new.cast(v) }
        start_month = aff["start_month"].presence&.to_i
        start_year  = aff["start_year"].presence&.to_i
        end_month   = current_flag ? nil : aff["end_month"].presence&.to_i
        end_year    = current_flag ? nil : aff["end_year"].presence&.to_i

        user_sport.user_sport_affiliations.create!(
          club_team_name: aff["club_team_name"],
          league_competition: aff["league_competition"],
          start_month: start_month,
          start_year: start_year,
          end_month: end_month,
          end_year: end_year,
          description: aff["description"],
          current: current_flag
        )
      end

      # Inline tournaments (supports both array and indexed-hash formats)
      tourn_param = attributes["tournaments"] || attributes[:tournaments]
      tourn_collection =
        if tourn_param.is_a?(Hash)
          tourn_param.values
        else
          Array(tourn_param)
        end
      tourn_collection.each do |t|
        next unless t.is_a?(Hash) || t.is_a?(ActionController::Parameters)
        t = t.to_unsafe_h if t.is_a?(ActionController::Parameters)
        next if t["tournament_name"].blank?
        user_sport.user_sport_tournaments.create!(
          tournament_name: t["tournament_name"],
          year: t["year"].presence&.to_i,
          description: t["description"]
        )
      end
    end
  end
end
