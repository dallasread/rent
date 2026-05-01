class LeaseCreated < RailsEventStore::Event
  # data: { lease_id:, property_id:, applicant_id:, start_date:, end_date:, mobile:, created_at: }
end
