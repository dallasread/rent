class RemoveProperty
  class NotFound < NotFoundError; end

  def self.call(slug:, actor:)
    Authorization.check!(actor: actor, key: name)
    current = PropertyBySlug.call(slug: slug).property
    raise NotFound, "Property not found." unless current

    event = PropertyRemoved.new(data: {
      property_id: current.id,
      mobile: actor,
      removed_at: Time.current
    })
    Rails.configuration.event_store.publish(event, stream_name: "Property$#{current.id}")
    Rails.configuration.event_store.link([ event.event_id ], stream_name: "Properties")
    nil
  end
end
