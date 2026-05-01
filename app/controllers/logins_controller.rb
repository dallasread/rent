class LoginsController < ApplicationController
  def new
    redirect_to dashboard_path if authenticated?
  end

  def create
    RequestLoginCode.call(mobile: params[:mobile], ip: request.remote_ip)
    cookies.signed[:pending_mobile] = { value: Mobile.normalize(params[:mobile]), expires: 15.minutes.from_now }
    redirect_to login_verify_path, notice: "Code sent."
  end

  def verify
    redirect_to login_path and return unless cookies.signed[:pending_mobile]
  end

  def submit
    mobile = cookies.signed[:pending_mobile]
    raise VerifyLoginCode::InvalidMobile, "Session expired. Please start again." unless mobile

    VerifyLoginCode.call(mobile: mobile, code: params[:code])

    token = LatestAuthToken.call(mobile: mobile).token
    cookies.signed[:auth_token] = { value: token, expires: 1.year.from_now, httponly: true }
    cookies.delete(:pending_mobile)
    redirect_to (admin? ? properties_path : dashboard_path), notice: "Logged in."
  end
end
