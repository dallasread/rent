class DashboardController < ApplicationController
  before_action :require_authentication

  def show
    @dashboard = UserDashboard.call(mobile: current_user.mobile)
  end
end
