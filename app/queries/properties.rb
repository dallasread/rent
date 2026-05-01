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
      .sort_by { |p| p.added_at || Time.current }

    Result.new(properties: properties)
  end
end
