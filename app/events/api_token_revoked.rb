class ApiTokenRevoked < RailsEventStore::Event
  # data: { token_id:, mobile:, revoked_at: }
end
