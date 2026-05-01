class Leases
  LeaseView = Data.define(:id, :property_id, :applicant_id, :start_date, :end_date, :created_at)
  Result = Data.define(:leases)

  def self.call
    events = Rails.configuration.event_store.read
      .stream("Leases")
      .of_type([ LeaseCreated ])
      .to_a

    leases = events.map do |e|
      LeaseView.new(
        id: e.data[:lease_id],
        property_id: e.data[:property_id],
        applicant_id: e.data[:applicant_id],
        start_date: Date.parse(e.data[:start_date]),
        end_date: e.data[:end_date] ? Date.parse(e.data[:end_date]) : nil,
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
