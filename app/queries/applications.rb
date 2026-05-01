class Applications
  ApplicationView = Data.define(:id, :property_id, :property_name, :property_slug, :name, :mobile, :summary, :submitted_at)
  Result = Data.define(:applications)

  def self.call
    events = Rails.configuration.event_store.read
      .stream("Applications")
      .of_type([ ApplicationSubmitted ])
      .to_a

    properties_by_id = Properties.call.properties.index_by(&:id)

    applications = events.map do |e|
      prop = properties_by_id[e.data[:property_id]]
      ApplicationView.new(
        id: e.data[:application_id],
        property_id: e.data[:property_id],
        property_name: prop&.name || "(deleted)",
        property_slug: prop&.slug,
        name: e.data[:name],
        mobile: e.data[:mobile],
        summary: e.data[:summary],
        submitted_at: e.data[:submitted_at]
      )
    end.sort_by { |a| a.name.to_s.downcase }

    Result.new(applications: applications)
  end
end
