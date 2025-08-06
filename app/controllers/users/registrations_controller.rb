class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [ :create ]
  before_action :configure_account_update_params, only: [ :update ]

  # GET /users/sign_up
  def new
    build_resource({})
    # Generate temporary password for phone-based registration
    resource.password = SecureRandom.hex(10)
    resource.password_confirmation = resource.password
    respond_with resource
  end

  # POST /users
  def create
    build_resource(sign_up_params)

    # Set a temporary password for phone-based registration
    resource.password = SecureRandom.hex(10) if resource.password.blank?
    resource.password_confirmation = resource.password if resource.password_confirmation.blank?

    resource.save
    yield resource if block_given?

    if resource.persisted?
      if resource.active_for_authentication?
        # Send phone verification instead of confirmation email
        if resource.phone.present?
          resource.generate_phone_verification_code
          redirect_to phone_verification_path(phone: resource.phone),
                     notice: "Please verify your phone number to complete registration."
        else
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, resource)
          redirect_to after_sign_up_path_for(resource)
        end
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        redirect_to after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      render :new, status: :unprocessable_entity
    end
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name, :phone, :user_type ])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name, :phone, :user_type ])
  end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    if resource.verified?
      # If user is verified, redirect them to their profile
      if resource.profile_completed?
        public_view_profile_path(resource.profile)
      elsif resource.profile
        edit_profile_path(resource.profile)
      else
        root_path
      end
    else
      # If user has phone, send to verification; otherwise go to root
      if resource.phone.present?
        phone_verification_path(phone: resource.phone)
      else
        root_path
      end
    end
  end

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(resource)
    if resource.phone.present?
      phone_verification_path(phone: resource.phone)
    else
      root_path
    end
  end
end
