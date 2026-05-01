class LoginCodeRequested < RailsEventStore::Event
  # data: { mobile:, code:, expires_at:, ip:, requested_at: }
end
