class DashboardController < ApplicationController
  def show
    @dashboard = UserDashboard.call(mobile: current_user.mobile)
  end
end
