class LeaseArchived < RailsEventStore::Event
  # data: { lease_id:, actor_id:, archived_at: }
end
