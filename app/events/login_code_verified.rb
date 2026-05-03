class LoginCodeVerified < RailsEventStore::Event
  # data: { user_id:, request_event_id:, token:, verified_at: }
end
