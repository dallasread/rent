class LeaseUpdated < RailsEventStore::Event
  # data: { lease_id:, start_date:, end_date:, mobile:, updated_at: }
end
