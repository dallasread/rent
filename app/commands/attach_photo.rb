class AttachPhoto
  class InvalidFile < CommandError; end
  class PropertyNotFound < NotFoundError; end

  ACCEPTED_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif image/heic image/heif].freeze

  def self.call(actor:, property_id:, file:)
    Authorization.check!(actor: actor, key: self.name)

    property = Property.call(property_id: property_id).property
    raise PropertyNotFound, "Property not found." unless property

    raise InvalidFile, "No file uploaded." if file.blank?
    raise InvalidFile, "Unsupported file type." unless ACCEPTED_CONTENT_TYPES.include?(file.content_type)

    blob = ActiveStorage::Blob.create_and_upload!(
      io: file.tempfile,
      filename: file.original_filename,
      content_type: file.content_type
    )

    event = PhotoAttached.new(data: {
      property_id: property_id,
      photo_id: SecureRandom.uuid,
      blob_id: blob.id,
      actor_id: actor,
      attached_at: Time.current
    })
    Rails.configuration.event_store.publish(event, stream_name: "Property$#{property_id}")
    Rails.configuration.event_store.link([ event.event_id ], stream_name: "Properties")
    nil
  end
end
