class UpdateProperty
  class NotFound < CommandError; end
  class InvalidName < CommandError; end

  def self.call(property_id:, mobile:, name:, beds:, baths:, description:)
    raise InvalidName, "Name is required." if name.to_s.strip.empty?
    current = Property.call(property_id: property_id).property
    raise NotFound, "Property not found." unless current

    event = PropertyUpdated.new(data: {
      property_id: property_id,
      mobile: mobile,
      name: name.to_s.strip,
      beds: beds.to_i,
      baths: baths.to_i,
      description: description.to_s,
      updated_at: Time.current
    })
    Rails.configuration.event_store.publish(event, stream_name: "Property$#{property_id}")
    Rails.configuration.event_store.link([ event.event_id ], stream_name: "Properties")
    nil
  end
end
