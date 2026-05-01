class Properties
  Result = Data.define(:properties)

  def self.call
    events = Rails.configuration.event_store.read
      .stream("Properties")
      .of_type(Property::EVENT_TYPES)
      .to_a

    grouped = events.group_by { |e| e.data[:property_id] }
    properties = grouped.values
      .map { |evs| Property::PropertyFold.call(evs) }
      .compact
      .sort_by { |p| (p.address.presence || p.name).to_s.downcase }

    Result.new(properties: properties)
  end
end
