class LoginCodeVerified < RailsEventStore::Event
  # data: { mobile:, request_event_id:, token:, verified_at: }
end
