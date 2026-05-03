class CreateUser
  # Idempotent by mobile: returns the existing user_id when one already
  # exists, otherwise publishes UserCreated and returns the new user_id.
  # Called from the login flow on first verify; intentionally not gated
  # by Authorization (the caller is mid-authentication and has no actor yet).
  def self.call(mobile:)
    normalized = Mobile.normalize(mobile)
    raise ArgumentError, "Invalid mobile" unless normalized

    existing = User.find_by_mobile(normalized)
    return existing.id if existing

    user_id = SecureRandom.uuid
    Rails.configuration.event_store.publish(
      UserCreated.new(data: {
        user_id: user_id,
        mobile: normalized,
        created_at: Time.current
      }),
      stream_name: "User$#{user_id}"
    )
    user_id
  end
end
