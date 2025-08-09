class PhoneVerificationController < ApplicationController
  # Deprecated: phone verification removed in favor of email verification.
  # Keep routes temporarily returning 404 or redirect.
  def show
    redirect_to new_user_session_path, alert: "Phone verification is no longer supported. Please sign in."
  end

  def verify
    redirect_to new_user_session_path, alert: "Phone verification is no longer supported. Please sign in."
  end

  def resend
    redirect_to new_user_session_path, alert: "Phone verification is no longer supported. Please sign in."
  end
end
