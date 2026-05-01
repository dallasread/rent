class Applications
  ApplicationView = Data.define(:id, :property_id, :name, :mobile, :summary, :archived?, :submitted_at)
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

    applications = events.map do |e|
      last_archive = archive_state[e.data[:application_id]]&.last
      ApplicationView.new(
        id: e.data[:application_id],
        property_id: e.data[:property_id],
        name: e.data[:name],
        mobile: e.data[:mobile],
        summary: e.data[:summary],
        archived?: last_archive.is_a?(ApplicantArchived),
        submitted_at: e.data[:submitted_at]
      )
    end

    applications = applications.reject(&:archived?) unless include_archived
    Result.new(applications: applications.sort_by { |a| a.name.to_s.downcase })
  end
end
