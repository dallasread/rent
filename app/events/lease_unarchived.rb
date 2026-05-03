class LeaseUnarchived < RailsEventStore::Event
  # data: { lease_id:, actor_id:, unarchived_at: }
end
