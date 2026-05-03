class UnarchiveApplicant
  def self.call(application_id:, actor:)
    Authorization.check!(actor: actor, key: name)
    Applicant.call(applicant_id: application_id)

    Rails.configuration.event_store.publish(
      ApplicantUnarchived.new(data: {
        application_id: application_id,
        actor_id: actor,
        unarchived_at: Time.current
      }),
      stream_name: "Applicant$#{application_id}"
    )
    nil
  end
end
