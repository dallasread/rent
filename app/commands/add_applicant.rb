class AddApplicant
  class InvalidName < CommandError; end
  class InvalidMobile < CommandError; end
  class InvalidSummary < CommandError; end
  class PropertyNotFound < CommandError; end

  def self.call(actor:, name:, mobile:, summary:, property_id: nil)
    Authorization.check!(actor: actor, key: self.name)

    raise InvalidName,    "Name is required."    if name.to_s.strip.empty?
    normalized_mobile = Mobile.normalize(mobile)
    raise InvalidMobile,  "Invalid mobile number." unless normalized_mobile
    raise InvalidSummary, "Summary is required." if summary.to_s.strip.empty?

    pid = property_id.presence
    if pid && Property.call(property_id: pid).property.nil?
      raise PropertyNotFound, "Property not found."
    end

    application_id = SecureRandom.uuid
    event = ApplicationSubmitted.new(data: {
      application_id: application_id,
      property_id: pid,
      name: name.to_s.strip,
      mobile: normalized_mobile,
      summary: summary.to_s.strip,
      submitted_at: Time.current
    })
    stream = pid ? "Property$#{pid}" : "Applications"
    Rails.configuration.event_store.publish(event, stream_name: stream)
    Rails.configuration.event_store.link([ event.event_id ], stream_name: "Applications") if pid
    nil
  end
end
