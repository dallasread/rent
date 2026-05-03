class AddProperty
  class InvalidName < CommandError; end

  def self.call(actor:, name:, address:, beds:, baths:, description:)
    Authorization.check!(actor: actor, key: self.name)
    raise InvalidName, "Name is required." if name.to_s.strip.empty?

    base = Slug.normalize(name) || "property"
    slug = Slug.unique_for(base, taken_slugs)

    property_id = SecureRandom.uuid
    event = PropertyAdded.new(data: {
      property_id: property_id,
      slug: slug,
      actor_id: actor,
      name: name.to_s.strip,
      address: address.to_s.strip,
      beds: beds.to_i,
      baths: baths.to_i,
      description: description.to_s,
      added_at: Time.current
    })
    Rails.configuration.event_store.publish(event, stream_name: "Property$#{property_id}")
    Rails.configuration.event_store.link([ event.event_id ], stream_name: "Properties")
    nil
  end

  def self.taken_slugs
    Properties.call.properties.map(&:slug).to_set
  end
end
