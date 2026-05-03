class SettingsController < ApplicationController
  def show
    @settings = Settings.call
  end

  def update
    UpdateSettings.call(
      actor: current_user.id,
      brand_name: params[:brand_name],
      primary_color: params[:primary_color],
      background_color: params[:background_color],
      text_color: params[:text_color],
      time_zone: params[:time_zone]
    )
    redirect_to settings_path, notice: "Settings saved."
  end
end
