class UpdateProperty
  class NotFound < CommandError; end
  class InvalidName < CommandError; end

  def self.call(property_id:, actor:, name:, address:, slug:, beds:, baths:, description:)
    Authorization.check!(actor: actor, key: self.name)
    raise InvalidName, "Name is required." if name.to_s.strip.empty?
    current = Property.call(property_id: property_id).property
    raise NotFound, "Property not found." unless current

    base = Slug.normalize(slug) || Slug.normalize(name) || "property"
    taken = Properties.call.properties.reject { |p| p.id == property_id }.map(&:slug).to_set
    final_slug = Slug.unique_for(base, taken)

    event = PropertyUpdated.new(data: {
      property_id: property_id,
      slug: final_slug,
      mobile: actor,
      name: name.to_s.strip,
      address: address.to_s.strip,
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
