class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [ :create ]
  before_action :configure_account_update_params, only: [ :update ]

  # GET /users/sign_up
  def new
    build_resource({})
    respond_with resource
  end

  # POST /users
  def create
    build_resource(sign_up_params)
    resource.save
    yield resource if block_given?

    if resource.persisted?
      # Create email contact and send OTP
      email_contact = resource.user_contacts.find_or_initialize_by(contact_type: :email, value: resource.email)
      email_contact.save! if email_contact.new_record?
      email_contact.generate_and_send_otp

      set_flash_message! :notice, :signed_up
      redirect_to verify_email_path(user_id: resource.id)
    else
      clean_up_passwords resource
      set_minimum_password_length
      render :new, status: :unprocessable_entity
    end
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name, :phone, :user_type, :username, :email ])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name, :phone, :user_type, :username, :email ])
  end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    verify_email_path(user_id: resource.id)
  end

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(resource)
    verify_email_path(user_id: resource.id)
  end
end
