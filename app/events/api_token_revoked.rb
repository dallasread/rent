class ApiTokenRevoked < RailsEventStore::Event
  # data: { token_id:, actor_id:, revoked_at: }
end
