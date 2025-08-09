class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :authenticate_with_jwt!, only: [ :login, :register, :verify_email, :resend_email_code ]

  # POST /api/v1/auth/register
  def register
    user = User.new(user_params)
    if user.save
      email_contact = user.user_contacts.find_or_initialize_by(contact_type: :email, value: user.email)
      email_contact.save! if email_contact.new_record?
      email_contact.generate_and_send_otp
      render_success({ user_id: user.id, username: user.username, email: user.email }, "Registration successful. Please verify your email.")
    else
      render_error("Registration failed", :unprocessable_entity, user.errors)
    end
  end

  # POST /api/v1/auth/login
  def login
    login_value = params[:login].to_s
    password = params[:password].to_s
    user = User.find_for_database_authentication(login: login_value)

    if user&.valid_password?(password)
      unless user.email_verified?
        return render_error("Email not verified", :unauthorized)
      end
      user.update!(last_sign_in_at: Time.current)
      token = generate_jwt_token(user)
      render_success({ token: token, user: user_data(user) }, "Login successful")
    else
      render_error("Invalid credentials", :unauthorized)
    end
  end

  # POST /api/v1/auth/verify_email
  def verify_email
    user = User.find_by(id: params[:user_id])
    return render_error("User not found", :not_found) unless user

    contact = user.user_contacts.find_by(contact_type: :email, value: user.email)
    return render_error("Verification not initiated", :unprocessable_entity) unless contact

    if contact.verify_code!(params[:verification_code])
      user.update!(last_sign_in_at: Time.current)
      token = generate_jwt_token(user)
      render_success({ token: token, user: user_data(user) }, "Email verified successfully")
    else
      render_error("Invalid or expired verification code", :unauthorized)
    end
  end

  # POST /api/v1/auth/resend_email_code
  def resend_email_code
    user = User.find_by(id: params[:user_id])
    return render_error("User not found", :not_found) unless user

    contact = user.user_contacts.find_or_create_by!(contact_type: :email, value: user.email)
    begin
      contact.generate_and_send_otp
      render_success({ email: user.email }, "New verification code sent")
    rescue => e
      render_error(e.message, :too_many_requests)
    end
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
    params.require(:user).permit(:first_name, :last_name, :phone, :user_type, :email, :username, :password, :password_confirmation)
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
      username: user.username,
      user_type: user.user_type,
      email_verified: user.email_verified?,
      profile_completed: user.profile_completed?,
      profile_id: user.profile&.id,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
end
