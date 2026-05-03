class LoggedOut < RailsEventStore::Event
  # data: { actor_id:, token:, logged_out_at: }
end
