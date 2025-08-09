class EmailVerificationController < ApplicationController
  def show
    @user = User.find(params[:user_id])
    @email = @user.email
  rescue ActiveRecord::RecordNotFound
    redirect_to new_user_registration_path, alert: "User not found"
  end

  def verify
    @user = User.find(params[:user_id])
    contact = @user.user_contacts.find_by(contact_type: :email, value: @user.email)
    unless contact
      redirect_to verify_email_path(user_id: @user.id), alert: "Verification not initiated"
      return
    end

    if contact.verify_code!(params[:verification_code])
      sign_in(@user)
      redirect_to after_sign_in_path_for(@user), notice: "Email verified successfully!"
    else
      redirect_to verify_email_path(user_id: @user.id), alert: "Invalid or expired code"
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to new_user_registration_path, alert: "User not found"
  end

  def resend
    @user = User.find(params[:user_id])
    contact = @user.user_contacts.find_or_create_by!(contact_type: :email, value: @user.email)
    contact.generate_and_send_otp
    redirect_to verify_email_path(user_id: @user.id), notice: "New verification code sent"
  rescue => e
    redirect_to verify_email_path(user_id: params[:user_id]), alert: e.message
  end
end
