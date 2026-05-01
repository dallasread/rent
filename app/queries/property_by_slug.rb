class PropertyBySlug
  Result = Data.define(:property)

  def self.call(slug:)
    added = Rails.configuration.event_store.read
      .stream("Slug$#{slug}")
      .of_type([ PropertyAdded ])
      .first
    return Result.new(property: nil) unless added

    Property.call(property_id: added.data[:property_id])
  end
end
