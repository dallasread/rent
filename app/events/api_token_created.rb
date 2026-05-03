class ApiTokenCreated < RailsEventStore::Event
  # data: { token_id:, name:, token:, actor_id:, created_at: }
end
