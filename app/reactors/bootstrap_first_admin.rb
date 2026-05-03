class BootstrapFirstAdmin
  def self.call(event)
    return if any_admin_exists?

    user_id = event.data[:user_id]
    Rails.configuration.event_store.publish(
      UserPromotedToAdmin.new(data: {
        user_id: user_id,
        actor_id: "system",
        promoted_at: Time.current
      }),
      stream_name: "User$#{user_id}"
    )
  end

  def self.any_admin_exists?
    Rails.configuration.event_store.read.of_type([ UserPromotedToAdmin ]).each.any?
  end
end
