class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile, only: [ :show, :edit, :update, :public_view ]
  before_action :ensure_own_profile, only: [ :edit, :update, :complete_setup ]

  # GET /profiles/:id
  def show
    redirect_to public_view_profile_path(@profile)
  end

  # GET /profiles/:id/public_view
  def public_view
    @user = @profile.user
    @user_sports = @profile.user.user_sports.includes(:sport)
    @is_own_profile = @profile.user == current_user
  end

  # GET /profiles/:id/edit
  def edit
    @sports = Sport.active.order(:name)
    @user_sports = @profile.user.user_sports.includes(:sport)
  end

  # PATCH /profiles/:id
  def update
    if @profile.update(profile_params)
      update_user_sports if params[:sports].present?

      if params[:complete_setup] == "true"
        redirect_to @profile, notice: "Profile setup completed successfully!"
      else
        redirect_to @profile, notice: "Profile updated successfully!"
      end
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
      redirect_to @profile, notice: "Welcome to LinkSports! Your profile is now complete."
    else
      @sports = Sport.active.order(:name)
      @user_sports = @profile.user.user_sports.includes(:sport)
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_profile
    @profile = Profile.find_by!(slug: params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Profile not found."
  end

  def ensure_own_profile
    unless @profile.user == current_user
      redirect_to @profile, alert: "You can only edit your own profile."
    end
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

    # Try the specific type first, fall back to generic profile
    profile_params = params[param_key] || params[:profile]
    return ActionController::Parameters.new unless profile_params

    # Base permitted params
    permitted = [ :first_name, :last_name, :display_name, :bio, :date_of_birth, :gender,
                 :location_city, :location_state, :location_country,
                 :website_url, :instagram_url, :youtube_url, :profile_image ]

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

    profile_params.permit(*permitted)
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
        primary: sport_data[:primary] == "1"
      )
    end
  end
end
