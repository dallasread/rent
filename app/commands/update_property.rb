class UpdateProperty
  class NotFound < NotFoundError; end
  class InvalidName < CommandError; end

  def self.call(slug:, actor:, name:, permalink:, address:, beds:, baths:, description:)
    Authorization.check!(actor: actor, key: self.name)
    raise InvalidName, "Name is required." if name.to_s.strip.empty?

    current = PropertyBySlug.call(slug: slug).property
    raise NotFound, "Property not found." unless current

    base = Slug.normalize(permalink) || Slug.normalize(name) || "property"
    taken = Properties.call.properties.reject { |p| p.id == current.id }.map(&:slug).to_set
    final_slug = Slug.unique_for(base, taken)

    event = PropertyUpdated.new(data: {
      property_id: current.id,
      slug: final_slug,
      mobile: actor,
      name: name.to_s.strip,
      address: address.to_s.strip,
      beds: beds.to_i,
      baths: baths.to_i,
      description: description.to_s,
      updated_at: Time.current
    })
    Rails.configuration.event_store.publish(event, stream_name: "Property$#{current.id}")
    Rails.configuration.event_store.link([ event.event_id ], stream_name: "Properties")
    nil
  end
end
