class Users::SessionsController < Devise::SessionsController
  before_action :configure_sign_in_params, only: [ :create ]

  # GET /users/sign_in
  def new
    super
  end

  # POST /users/sign_in
  def create
    # Check if user is trying to login with phone
    if params[:user][:phone].present?
      login_with_phone
    else
      super
    end
  end

  # DELETE /users/sign_out
  def destroy
    super
  end

  protected

  def login_with_phone
    phone = format_phone_for_lookup(params[:user][:phone])
    user = User.find_by(phone: phone)

    if user&.verified?
      # Generate and send verification code for login
      user.generate_phone_verification_code
      redirect_to phone_verification_path(phone: user.phone, login: true),
                 notice: "Verification code sent to your phone."
    else
      # Initialize resource for the form to work properly
      self.resource = resource_class.new(sign_in_params)
      set_flash_message!(:alert, :not_found_in_database, authentication_keys: "phone number")
      render :new, status: :unprocessable_entity
    end
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [ :phone ])
  end

  def sign_in_params
    return {} unless params[:user].present?
    params.require(:user).permit(:email, :password, :phone, :remember_me)
  end

  def format_phone_for_lookup(phone)
    return phone unless phone.present?

    # Remove all non-digits
    formatted = phone.gsub(/\D/, "")

    # Add country code for India if not present
    formatted = "91#{formatted}" unless formatted.start_with?("91")

    # Add + prefix
    "+#{formatted}"
  end
end
