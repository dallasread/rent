class ApplicantArchived < RailsEventStore::Event
  # data: { application_id:, mobile:, archived_at: }
end
