class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :check_profile_completion, if: :user_signed_in?

  protected

  def check_profile_completion
    return unless user_signed_in?
    return if current_user.profile_completed?
    return if skip_profile_completion_check?

    # Redirect to profile setup if not completed
    redirect_to edit_profile_path(current_user.profile),
               notice: "Please complete your profile setup to continue."
  end

  private

  def skip_profile_completion_check?
    # Skip check for these controllers/actions
    devise_controller? ||
    controller_name == "profiles" ||
    controller_name == "phone_verification" ||
    (controller_name == "home" && action_name == "index")
  end
end
