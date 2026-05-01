class LeaseArchived < RailsEventStore::Event
  # data: { lease_id:, mobile:, archived_at: }
end
