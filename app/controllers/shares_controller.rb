class SharesController < ApplicationController
  skip_before_action :check_profile_completion
  before_action :set_profile, only: [ :show ]

  # GET /profile/:username
  def show
    @user = @profile.user
    @user_sports = @profile.user.user_sports.includes(:sport)
    @is_own_profile = user_signed_in? && @profile.user == current_user

    # Set meta tags for social sharing
    @meta_title = "#{@profile.display_name} - #{@user.user_type.titleize} on LinkSports"
    @meta_description = if @profile.bio.present?
      @profile.bio.to_s.truncate(160)
    else
      "Connect with #{@profile.display_name} on LinkSports - India's premier sports networking platform"
    end
    @meta_image = @profile.profile_image.attached? ?
                 url_for(@profile.profile_image) :
                 "#{request.protocol}#{request.host_with_port}/icon.png"
    @canonical_url = public_profile_url(username: @profile.user.username)

    render "profiles/show", layout: "sharing"
  end

  private

  def set_profile
    @user = User.find_by!(username: params[:username].to_s.downcase)
    @profile = @user.profile
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Profile not found."
  end
end
