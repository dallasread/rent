class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :authorize_action!
  rescue_from Authorization::Unauthenticated, with: :handle_unauthenticated
  rescue_from Authorization::Forbidden, with: :handle_forbidden
  rescue_from NotFoundError, with: :handle_not_found
  rescue_from CommandError, with: :handle_command_error

  helper_method :current_user, :authenticated?, :admin?

  private

  def current_user
    @current_user ||= bearer_token.present? ?
      CurrentUserByApiToken.call(token: bearer_token) :
      CurrentUser.call(token: cookies.signed[:auth_token])
  end

  def bearer_token
    @bearer_token ||= request.headers["Authorization"].to_s[/\ABearer (.+)\z/, 1].to_s
  end

  def authenticated?
    current_user.authenticated?
  end

  def admin?
    authenticated? && IsAdmin.call(mobile: current_user.mobile).admin?
  end

  def require_authentication
    redirect_to login_path unless authenticated?
  end

  def authorize_action!
    Authorization.check!(
      actor: current_user.mobile,
      key: "#{controller_name.camelize}##{action_name}"
    )
  end

  def handle_unauthenticated(error)
    respond_to do |format|
      format.html { redirect_to login_path, alert: error.message }
      format.json { render json: { error: error.message }, status: :unauthorized }
    end
  end

  def handle_forbidden(error)
    respond_to do |format|
      format.html { redirect_back fallback_location: login_path, alert: error.message }
      format.json { render json: { error: error.message }, status: :forbidden }
    end
  end

  def handle_not_found(error)
    respond_to do |format|
      format.html { render file: Rails.root.join("public/404.html"), status: :not_found, layout: false, content_type: "text/html" }
      format.json { render json: { error: error.message }, status: :not_found }
    end
  end

  def handle_command_error(error)
    respond_to do |format|
      format.html { redirect_back fallback_location: login_path, alert: error.message }
      format.json { render json: { error: error.message }, status: :unprocessable_entity }
    end
  end
end
