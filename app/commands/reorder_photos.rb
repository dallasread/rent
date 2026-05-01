class ReorderPhotos
  class PropertyNotFound < NotFoundError; end
  class InvalidOrder < CommandError; end

  def self.call(actor:, property_id:, photo_ids:)
    Authorization.check!(actor: actor, key: self.name)

    property = Property.call(property_id: property_id).property
    raise PropertyNotFound, "Property not found." unless property

    current_ids = property.photos.map(&:id)
    given = Array(photo_ids)
    raise InvalidOrder, "Order must contain every current photo exactly once." unless given.sort == current_ids.sort

    event = PhotosReordered.new(data: {
      property_id: property_id,
      ordered_photo_ids: given,
      mobile: actor,
      reordered_at: Time.current
    })
    Rails.configuration.event_store.publish(event, stream_name: "Property$#{property_id}")
    Rails.configuration.event_store.link([ event.event_id ], stream_name: "Properties")
    nil
  end
end
