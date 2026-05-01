class SubmitApplication
  class PropertyNotFound < NotFoundError; end
  class PropertyNotPublished < CommandError; end
  class InvalidName < CommandError; end
  class InvalidMobile < CommandError; end
  class InvalidSummary < CommandError; end

  def self.call(slug:, name:, mobile:, summary:, actor: nil)
    Authorization.check!(actor: actor, key: self.name)

    property = PropertyBySlug.call(slug: slug).property
    raise PropertyNotFound, "Property not found." unless property
    raise PropertyNotPublished, "This property is not accepting applications." unless property.published

    raise InvalidName, "Name is required." if name.to_s.strip.empty?
    normalized_mobile = Mobile.normalize(mobile)
    raise InvalidMobile, "Invalid mobile number." unless normalized_mobile
    raise InvalidSummary, "Tell us a little about yourself." if summary.to_s.strip.empty?

    application_id = SecureRandom.uuid
    event = ApplicationSubmitted.new(data: {
      application_id: application_id,
      property_id: property.id,
      name: name.to_s.strip,
      mobile: normalized_mobile,
      summary: summary.to_s.strip,
      submitted_at: Time.current
    })
    Rails.configuration.event_store.publish(event, stream_name: "Property$#{property.id}")
    Rails.configuration.event_store.link([ event.event_id ], stream_name: "Applications")
    nil
  end
end
