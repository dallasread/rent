class AddProperty
  class InvalidName < CommandError; end

  def self.call(mobile:, name:, beds:, baths:, description:)
    raise InvalidName, "Name is required." if name.to_s.strip.empty?

    property_id = SecureRandom.uuid
    event = PropertyAdded.new(data: {
      property_id: property_id,
      mobile: mobile,
      name: name.to_s.strip,
      beds: beds.to_i,
      baths: baths.to_i,
      description: description.to_s,
      added_at: Time.current
    })
    Rails.configuration.event_store.publish(event, stream_name: "Property$#{property_id}")
    Rails.configuration.event_store.link([ event.event_id ], stream_name: "Properties")
    nil
  end
end
