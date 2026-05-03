class LeaseCreated < RailsEventStore::Event
  # data: { lease_id:, property_id:, applicant_id:, start_date:, end_date:, rent_cents:, frequency:, actor_id:, created_at: }
end
