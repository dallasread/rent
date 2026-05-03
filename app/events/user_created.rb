class UserCreated < RailsEventStore::Event
  # data: { user_id:, mobile:, created_at: }
  #
  # The User aggregate decouples actor identity (a stable UUID) from the
  # mobile number, which is mutable PII. Every event that records who
  # performed an action stores `actor_id:` (a user_id), not the mobile.
  # The mobile is resolved for display via the User lookup.
end
