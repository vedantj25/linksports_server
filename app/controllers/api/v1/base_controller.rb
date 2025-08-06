class Api::V1::BaseController < ApplicationController
  # Skip CSRF token verification for API requests
  skip_before_action :verify_authenticity_token
  skip_before_action :check_profile_completion

  # Use JSON format by default
  before_action :set_default_format

  # JWT Authentication
  before_action :authenticate_with_jwt!

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  protected

  def authenticate_with_jwt!
    token = request.headers["Authorization"]&.split(" ")&.last
    return render_unauthorized unless token

    begin
      decoded = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: "HS256" })
      user_id = decoded[0]["user_id"]
      @current_user = User.find(user_id)
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render_unauthorized
    end
  end

  def current_user
    @current_user
  end

  def user_signed_in?
    @current_user.present?
  end

  private

  def set_default_format
    request.format = :json
  end

  def render_unauthorized
    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def render_success(data = {}, message = "Success")
    render json: {
      success: true,
      message: message,
      data: data
    }, status: :ok
  end

  def render_error(message, status = :unprocessable_entity, errors = nil)
    response = {
      success: false,
      message: message
    }
    response[:errors] = errors if errors

    render json: response, status: status
  end

  def record_not_found(exception)
    render_error("Record not found", :not_found)
  end

  def record_invalid(exception)
    render_error("Validation failed", :unprocessable_entity, exception.record.errors)
  end

  def parameter_missing(exception)
    render_error("Missing parameter: #{exception.param}", :bad_request)
  end
end
