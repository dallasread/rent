class DuplicateProperty
  class NotFound < NotFoundError; end

  def self.call(slug:, actor:)
    Authorization.check!(actor: actor, key: name)
    source = PropertyBySlug.call(slug: slug).property
    raise NotFound, "Property not found." unless source

    AddProperty.call(
      actor: actor,
      name: "#{source.name} (copy)",
      address: source.address,
      beds: source.beds,
      baths: source.baths,
      description: source.description
    )
  end
end
