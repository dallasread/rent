class LogOut
  def self.call(token:)
    return nil if token.blank?

    verified = Rails.configuration.event_store.read
      .stream("Token$#{token}")
      .of_type([ LoginCodeVerified ])
      .first
    return nil unless verified

    Rails.configuration.event_store.publish(
      LoggedOut.new(data: {
        mobile: verified.data[:mobile],
        token: token,
        logged_out_at: Time.current
      }),
      stream_name: "Token$#{token}"
    )
    nil
  end
end
