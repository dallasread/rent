class SessionsController < ApplicationController
  def destroy
    LogOut.call(token: cookies.signed[:auth_token])
    cookies.delete(:auth_token)
    redirect_to login_path, notice: "Logged out."
  end
end
