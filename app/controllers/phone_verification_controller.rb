class PhoneVerificationController < ApplicationController
  before_action :find_user_by_phone

  # GET /phone_verification
  def show
    @phone = params[:phone]
    @login_mode = params[:login] == "true"

    if @user.nil?
      redirect_to new_user_registration_path, alert: "Phone number not found."
      return
    end

    # If user is already verified and not in login mode, redirect to sign in
    if @user.verified? && !@login_mode
      redirect_to new_user_session_path, notice: "Phone number already verified. Please sign in."
      return
    end

    # If verification code has expired, generate a new one
    if @user.phone_verification_sent_at.nil? || @user.phone_verification_sent_at < 10.minutes.ago
      @user.generate_phone_verification_code
    end
  end

  # POST /phone_verification
  def verify
    @phone = params[:phone]
    @login_mode = params[:login] == "true"
    verification_code = params[:verification_code]

    if @user.nil?
      redirect_to new_user_registration_path, alert: "Phone number not found."
      return
    end

    if @user.phone_verification_code_valid?(verification_code)
      if @login_mode
        # Login the user
        @user.update!(last_sign_in_at: Time.current)
        sign_in(@user)
        redirect_to after_sign_in_path_for(@user), notice: "Successfully signed in!"
      else
        # Complete registration verification
        @user.verify_phone!
        sign_in(@user)
        redirect_to after_sign_up_path_for(@user), notice: "Phone verified successfully! Welcome to LinkSports!"
      end
    else
      flash.now[:alert] = "Invalid or expired verification code. Please try again."
      render :show, status: :unprocessable_entity
    end
  end

  # POST /phone_verification/resend
  def resend
    @phone = params[:phone]

    if @user.nil?
      redirect_to new_user_registration_path, alert: "Phone number not found."
      return
    end

    @user.generate_phone_verification_code
    redirect_to phone_verification_path(phone: @phone, login: params[:login]),
               notice: "New verification code sent to your phone."
  end

  private

  def find_user_by_phone
    @user = User.find_by(phone: params[:phone]) if params[:phone].present?
  end

  def after_sign_up_path_for(user)
    if user.profile_completed?
      public_view_profile_path(user.profile)
    else
      edit_profile_path(user.profile)
    end
  end

  def after_sign_in_path_for(user)
    stored_location_for(user) || root_path
  end
end
