class Leases
  LeaseView = Data.define(:id, :property_id, :applicant_id, :start_date, :end_date, :created_at) do
    def name
      "#{start_date} → #{end_date || "open"}"
    end
  end
  Result = Data.define(:leases)

  def self.call
    created_events = Rails.configuration.event_store.read
      .stream("Leases")
      .of_type([ LeaseCreated ])
      .to_a

    updates_by_lease = Rails.configuration.event_store.read
      .of_type([ LeaseUpdated ])
      .to_a
      .group_by { |e| e.data[:lease_id] }

    leases = created_events.map do |e|
      lease_id = e.data[:lease_id]
      latest_dates = updates_by_lease[lease_id]&.last || e
      LeaseView.new(
        id: lease_id,
        property_id: e.data[:property_id],
        applicant_id: e.data[:applicant_id],
        start_date: Date.parse(latest_dates.data[:start_date]),
        end_date: latest_dates.data[:end_date] ? Date.parse(latest_dates.data[:end_date]) : nil,
        created_at: e.data[:created_at]
      )
    end

    properties = Properties.call.properties.index_by(&:id)
    applicants = Applications.call.applications.index_by(&:id)

    Result.new(leases: leases.sort_by { |l|
      [
        properties[l.property_id]&.name.to_s.downcase,
        applicants[l.applicant_id]&.name.to_s.downcase
      ]
    })
  end
end
