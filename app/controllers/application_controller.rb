class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :authorize_action!
  rescue_from CommandError, with: :handle_command_error

  helper_method :current_user, :authenticated?, :admin?

  private

  def current_user
    @current_user ||= CurrentUser.call(token: cookies.signed[:auth_token])
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

  def handle_command_error(error)
    redirect_back fallback_location: login_path, alert: error.message
  end
end
