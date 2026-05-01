class PublishProperty
  class NotFound < CommandError; end

  def self.call(property_id:, actor:)
    Authorization.check!(actor: actor, key: name)
    current = Property.call(property_id: property_id).property
    raise NotFound, "Property not found." unless current

    event = PropertyPublished.new(data: {
      property_id: property_id,
      mobile: actor,
      published_at: Time.current
    })
    Rails.configuration.event_store.publish(event, stream_name: "Property$#{property_id}")
    Rails.configuration.event_store.link([ event.event_id ], stream_name: "Properties")
    nil
  end
end
