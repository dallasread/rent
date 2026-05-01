class Settings
  Result = Data.define(:brand_name, :primary_color, :background_color, :text_color, :time_zone, :updated_at)

  DEFAULTS = {
    brand_name: "Acme Inc.",
    primary_color: "#b09353",
    background_color: "#0c0c0c",
    text_color: "#ffffff",
    time_zone: "UTC"
  }.freeze

  def self.call
    event = Rails.configuration.event_store.read
      .stream("Settings")
      .of_type([ SettingsUpdated ])
      .backward
      .first

    if event
      Result.new(
        brand_name: event.data[:brand_name].to_s,
        primary_color: event.data[:primary_color].to_s,
        background_color: event.data[:background_color].to_s.presence || DEFAULTS[:background_color],
        text_color: event.data[:text_color].to_s.presence || DEFAULTS[:text_color],
        time_zone: event.data[:time_zone].to_s.presence || DEFAULTS[:time_zone],
        updated_at: event.data[:updated_at]
      )
    else
      Result.new(**DEFAULTS, updated_at: nil)
    end
  end
end
