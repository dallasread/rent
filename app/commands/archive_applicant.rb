class ArchiveApplicant
  def self.call(application_id:, actor:)
    Authorization.check!(actor: actor, key: name)
    Applicant.call(applicant_id: application_id)  # raises if not found

    Rails.configuration.event_store.publish(
      ApplicantArchived.new(data: {
        application_id: application_id,
        actor_id: actor,
        archived_at: Time.current
      }),
      stream_name: "Applicant$#{application_id}"
    )
    nil
  end
end
