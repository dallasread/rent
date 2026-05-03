class ApplicantArchived < RailsEventStore::Event
  # data: { application_id:, actor_id:, archived_at: }
end
