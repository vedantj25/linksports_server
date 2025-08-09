module Admin
  class ApplicationController < ::ApplicationController
    include AdminLayout
    before_action :authenticate_user!
    before_action :enforce_admin_session_timeout
    before_action :require_admin!

    # place for audit whodunnit if needed

    ADMIN_SESSION_TIMEOUT_SECONDS = 30.minutes.to_i

    private

    def require_admin!
      unless current_user&.respond_to?(:role) && current_user.admin?
        redirect_to root_path, alert: "You are not authorized to access the admin area."
      end
    end

    def enforce_admin_session_timeout
      last_seen = session[:admin_last_seen_at].to_i
      now = Time.current.to_i
      if last_seen.positive? && (now - last_seen) > ADMIN_SESSION_TIMEOUT_SECONDS
        sign_out(current_user)
        reset_session
        redirect_to new_user_session_path, alert: "Your admin session has timed out. Please sign in again." and return
      end
      session[:admin_last_seen_at] = now
    end
  end
end
