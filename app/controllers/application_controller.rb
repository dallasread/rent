class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  rescue_from CommandError, with: :handle_command_error

  helper_method :current_user, :authenticated?

  private

  def current_user
    @current_user ||= CurrentUser.call(token: cookies.signed[:auth_token])
  end

  def authenticated?
    current_user.authenticated?
  end

  def require_authentication
    redirect_to login_path unless authenticated?
  end

  def handle_command_error(error)
    redirect_back fallback_location: login_path, alert: error.message
  end
end
