class RemoveProperty
  class NotFound < CommandError; end

  def self.call(property_id:, mobile:)
    current = Property.call(property_id: property_id).property
    raise NotFound, "Property not found." unless current

    event = PropertyRemoved.new(data: {
      property_id: property_id,
      mobile: mobile,
      removed_at: Time.current
    })
    Rails.configuration.event_store.publish(event, stream_name: "Property$#{property_id}")
    Rails.configuration.event_store.link([ event.event_id ], stream_name: "Properties")
    nil
  end
end
