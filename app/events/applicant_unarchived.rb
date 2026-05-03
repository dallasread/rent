class ApplicantUnarchived < RailsEventStore::Event
  # data: { application_id:, actor_id:, unarchived_at: }
end
