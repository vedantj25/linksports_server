module Admin
  class ProfilesController < ApplicationController
    before_action :set_profile, only: [:show, :edit, :update]

    def index
      @profiles = Profile.includes(:user).order(created_at: :desc).page(params[:page]).per(25)
    end

    def show; end

    def edit; end

    def update
      permitted = params.require(:profile).permit(:first_name, :last_name, :display_name, :bio, :location_city, :location_state, :website_url, :instagram_url, :youtube_url)
      if @profile.update(permitted)
        AuditLog.create!(admin_user: current_user, action: "update_profile", record_type: "Profile", record_id: @profile.id, changeset: @profile.previous_changes.except(:updated_at))
        redirect_to admin_profile_path(@profile), notice: "Profile updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_profile
      @profile = Profile.find(params[:id])
    end
  end
end


