class Leases
  LeaseView = Data.define(
    :id, :property_id, :property_name, :property_slug,
    :applicant_id, :applicant_name, :applicant_mobile,
    :start_date, :end_date, :created_at
  )
  Result = Data.define(:leases)

  def self.call
    events = Rails.configuration.event_store.read
      .stream("Leases")
      .of_type([ LeaseCreated ])
      .to_a

    properties = Properties.call.properties.index_by(&:id)
    applicants = Applications.call.applications.index_by(&:id)

    leases = events.map do |e|
      prop = properties[e.data[:property_id]]
      app  = applicants[e.data[:applicant_id]]
      LeaseView.new(
        id: e.data[:lease_id],
        property_id: e.data[:property_id],
        property_name: prop&.name || "(deleted)",
        property_slug: prop&.slug,
        applicant_id: e.data[:applicant_id],
        applicant_name: app&.name || "(deleted)",
        applicant_mobile: app&.mobile,
        start_date: Date.parse(e.data[:start_date]),
        end_date: e.data[:end_date] ? Date.parse(e.data[:end_date]) : nil,
        created_at: e.data[:created_at]
      )
    end

    Result.new(leases: leases.sort_by(&:start_date))
  end
end
