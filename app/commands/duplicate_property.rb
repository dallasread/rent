class DuplicateProperty
  class NotFound < CommandError; end

  def self.call(property_id:, actor:)
    Authorization.check!(actor: actor, key: name)
    source = Property.call(property_id: property_id).property
    raise NotFound, "Property not found." unless source

    AddProperty.call(
      actor: actor,
      name: "#{source.name} (copy)",
      beds: source.beds,
      baths: source.baths,
      description: source.description
    )
  end
end
