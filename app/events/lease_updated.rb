class LeaseUpdated < RailsEventStore::Event
  # data: { lease_id:, start_date:, end_date:, rent_cents:, frequency:, actor_id:, updated_at: }
end
