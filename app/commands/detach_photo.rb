class DetachPhoto
  class PropertyNotFound < NotFoundError; end
  class PhotoNotFound < NotFoundError; end

  def self.call(actor:, property_id:, photo_id:)
    Authorization.check!(actor: actor, key: self.name)

    property = Property.call(property_id: property_id).property
    raise PropertyNotFound, "Property not found." unless property
    raise PhotoNotFound, "Photo not found." unless property.photos.any? { |p| p.id == photo_id }

    event = PhotoDetached.new(data: {
      property_id: property_id,
      photo_id: photo_id,
      mobile: actor,
      detached_at: Time.current
    })
    Rails.configuration.event_store.publish(event, stream_name: "Property$#{property_id}")
    Rails.configuration.event_store.link([ event.event_id ], stream_name: "Properties")
    nil
  end
end
