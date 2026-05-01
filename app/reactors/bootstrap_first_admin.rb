class BootstrapFirstAdmin
  def self.call(event)
    return if any_admin_exists?

    Rails.configuration.event_store.publish(
      UserPromotedToAdmin.new(data: {
        mobile: event.data[:mobile],
        promoted_by: "system",
        promoted_at: Time.current
      }),
      stream_name: "Mobile$#{event.data[:mobile]}"
    )
  end

  def self.any_admin_exists?
    Rails.configuration.event_store.read.of_type([ UserPromotedToAdmin ]).each.any?
  end
end
