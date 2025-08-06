class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :authenticate_with_jwt!, only: [ :login, :register, :verify_phone, :resend_code ]

  # POST /api/v1/auth/register
  def register
    user = User.new(user_params)
    user.password = SecureRandom.hex(10) # Generate random password for phone-based auth
    user.password_confirmation = user.password

    if user.save
      user.generate_phone_verification_code
      render_success({
        user_id: user.id,
        phone: user.phone,
        message: "Verification code sent to your phone"
      }, "Registration successful. Please verify your phone number.")
    else
      render_error("Registration failed", :unprocessable_entity, user.errors)
    end
  end

  # POST /api/v1/auth/login
  def login
    phone = params[:phone]
    user = User.find_by(phone: phone)

    if user&.verified?
      user.generate_phone_verification_code
      render_success({
        user_id: user.id,
        phone: user.phone
      }, "Verification code sent to your phone")
    else
      render_error("Phone number not found or not verified", :not_found)
    end
  end

  # POST /api/v1/auth/verify_phone
  def verify_phone
    user = User.find_by(id: params[:user_id])
    verification_code = params[:verification_code]

    unless user
      return render_error("User not found", :not_found)
    end

    if user.phone_verification_code_valid?(verification_code)
      if params[:type] == "registration"
        user.verify_phone!
      end

      user.update!(last_sign_in_at: Time.current)
      token = generate_jwt_token(user)

      render_success({
        token: token,
        user: user_data(user)
      }, "Phone verified successfully")
    else
      render_error("Invalid or expired verification code", :unauthorized)
    end
  end

  # POST /api/v1/auth/resend_code
  def resend_code
    user = User.find_by(id: params[:user_id])

    unless user
      return render_error("User not found", :not_found)
    end

    user.generate_phone_verification_code
    render_success({ phone: user.phone }, "New verification code sent")
  end

  # POST /api/v1/auth/logout
  def logout
    # For JWT, we could implement token blacklisting here
    # For now, we'll just return success and let the client handle token removal
    render_success({}, "Logged out successfully")
  end

  # GET /api/v1/auth/me
  def me
    render_success({ user: user_data(current_user) })
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :phone, :user_type, :email)
  end

  def generate_jwt_token(user)
    payload = {
      user_id: user.id,
      exp: 30.days.from_now.to_i
    }
    JWT.encode(payload, Rails.application.credentials.secret_key_base, "HS256")
  end

  def user_data(user)
    {
      id: user.id,
      first_name: user.first_name,
      last_name: user.last_name,
      display_name: user.display_name,
      phone: user.phone,
      email: user.email,
      user_type: user.user_type,
      verified: user.verified?,
      profile_completed: user.profile_completed?,
      profile_id: user.profile&.id,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
end
