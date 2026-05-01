class Leases
  LeaseView = Data.define(:id, :property_id, :applicant_id, :start_date, :end_date, :rent_cents, :frequency, :archived?, :created_at) do
    def name
      "#{start_date} → #{end_date || "open"}"
    end

    def active_on?(date)
      !archived? && start_date <= date && (end_date.nil? || end_date >= date)
    end
  end

  Result = Data.define(:leases)

  def self.call(include_archived: false)
    created_events = Rails.configuration.event_store.read
      .stream("Leases")
      .of_type([ LeaseCreated ])
      .to_a

    updates_by_lease = Rails.configuration.event_store.read
      .of_type([ LeaseUpdated ])
      .to_a
      .group_by { |e| e.data[:lease_id] }

    archive_events = Rails.configuration.event_store.read
      .of_type([ LeaseArchived, LeaseUnarchived ])
      .to_a
      .group_by { |e| e.data[:lease_id] }

    leases = created_events.map do |e|
      lease_id = e.data[:lease_id]
      latest = updates_by_lease[lease_id]&.last || e
      last_archive = archive_events[lease_id]&.last
      archived = last_archive.is_a?(LeaseArchived)

      LeaseView.new(
        id: lease_id,
        property_id: e.data[:property_id],
        applicant_id: e.data[:applicant_id],
        start_date: Date.parse(latest.data[:start_date]),
        end_date: latest.data[:end_date] ? Date.parse(latest.data[:end_date]) : nil,
        rent_cents: (latest.data[:rent_cents] || e.data[:rent_cents] || 0).to_i,
        frequency: (latest.data[:frequency] || e.data[:frequency] || "monthly").to_s,
        archived?: archived,
        created_at: e.data[:created_at]
      )
    end

    leases = leases.reject(&:archived?) unless include_archived

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
