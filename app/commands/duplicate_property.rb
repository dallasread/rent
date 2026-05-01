class DuplicateProperty
  class NotFound < CommandError; end

  def self.call(property_id:, mobile:)
    source = Property.call(property_id: property_id).property
    raise NotFound, "Property not found." unless source

    AddProperty.call(
      mobile: mobile,
      name: "#{source.name} (copy)",
      beds: source.beds,
      baths: source.baths,
      description: source.description
    )
  end
end
