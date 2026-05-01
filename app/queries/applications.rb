class Applications
  ApplicationView = Data.define(:id, :property_id, :name, :mobile, :summary, :submitted_at)
  Result = Data.define(:applications)

  def self.call
    events = Rails.configuration.event_store.read
      .stream("Applications")
      .of_type([ ApplicationSubmitted ])
      .to_a

    applications = events.map do |e|
      ApplicationView.new(
        id: e.data[:application_id],
        property_id: e.data[:property_id],
        name: e.data[:name],
        mobile: e.data[:mobile],
        summary: e.data[:summary],
        submitted_at: e.data[:submitted_at]
      )
    end.sort_by { |a| a.name.to_s.downcase }

    Result.new(applications: applications)
  end
end
