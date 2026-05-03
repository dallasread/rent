class Applications
  # `summary` is the immutable intake pitch (from ApplicationSubmitted).
  # `notes`   is the editable, landlord-managed field set via UpdateTenantDetails.
  # `name` and `mobile` are folded from the latest TenantDetailsUpdated when present.
  ApplicationView = Data.define(:id, :property_id, :name, :mobile, :summary, :notes, :archived?, :submitted_at)
  Result = Data.define(:applications)

  def self.call(include_archived: false)
    events = Rails.configuration.event_store.read
      .stream("Applications")
      .of_type([ ApplicationSubmitted ])
      .to_a

    archive_state = Rails.configuration.event_store.read
      .of_type([ ApplicantArchived, ApplicantUnarchived ])
      .to_a
      .group_by { |e| e.data[:application_id] }

    detail_updates = Rails.configuration.event_store.read
      .of_type([ TenantDetailsUpdated ])
      .to_a
      .group_by { |e| e.data[:application_id] }

    applications = events.map do |e|
      last_archive = archive_state[e.data[:application_id]]&.last
      latest_update = detail_updates[e.data[:application_id]]&.last&.data || {}
      ApplicationView.new(
        id: e.data[:application_id],
        property_id: e.data[:property_id],
        name: latest_update[:name].presence || e.data[:name],
        mobile: latest_update[:new_mobile].presence || e.data[:mobile],
        summary: e.data[:summary],
        notes: latest_update[:notes],
        archived?: last_archive.is_a?(ApplicantArchived),
        submitted_at: e.data[:submitted_at]
      )
    end

    applications = applications.reject(&:archived?) unless include_archived
    Result.new(applications: applications.sort_by { |a| a.name.to_s.downcase })
  end
end
