class UpdateSettings
  class InvalidBrandName < CommandError; end
  class InvalidColor < CommandError; end

  COLOR_RE = /\A#[0-9a-fA-F]{3}([0-9a-fA-F]{3})?\z/

  def self.call(actor:, brand_name:, primary_color:, background_color:, text_color:)
    Authorization.check!(actor: actor, key: self.name)

    raise InvalidBrandName, "Brand name is required." if brand_name.to_s.strip.empty?
    [
      [ primary_color, "Primary" ],
      [ background_color, "Background" ],
      [ text_color, "Text" ]
    ].each do |val, label|
      raise InvalidColor, "#{label} color must be a hex code (e.g. #2563eb)." unless val.to_s.match?(COLOR_RE)
    end

    Rails.configuration.event_store.publish(
      SettingsUpdated.new(data: {
        brand_name: brand_name.to_s.strip,
        primary_color: primary_color.to_s,
        background_color: background_color.to_s,
        text_color: text_color.to_s,
        mobile: actor,
        updated_at: Time.current
      }),
      stream_name: "Settings"
    )
    nil
  end
end
