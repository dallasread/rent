class VerifyLoginCode
  class InvalidMobile < CommandError; end
  class InvalidCode < CommandError; end

  def self.call(mobile:, code:)
    normalized = Mobile.normalize(mobile)
    raise InvalidMobile, "Invalid mobile number." unless normalized

    request = latest_unverified_request(normalized)
    raise InvalidCode, "Invalid or expired code." unless request
    raise InvalidCode, "Invalid or expired code." if Time.current >= request.data[:expires_at]
    raise InvalidCode, "Invalid or expired code." unless ActiveSupport::SecurityUtils.secure_compare(request.data[:code].to_s, code.to_s)

    token = SecureRandom.hex(32)
    event = LoginCodeVerified.new(data: {
      mobile: normalized,
      request_event_id: request.event_id,
      token: token,
      verified_at: Time.current
    })
    Rails.configuration.event_store.publish(event, stream_name: "Mobile$#{normalized}")
    Rails.configuration.event_store.link([event.event_id], stream_name: "Token$#{token}")
    nil
  end

  def self.latest_unverified_request(mobile)
    events = Rails.configuration.event_store.read
      .stream("Mobile$#{mobile}")
      .of_type([LoginCodeRequested, LoginCodeVerified])
      .backward
      .limit(20)
      .to_a
    last_request = events.find { |e| e.is_a?(LoginCodeRequested) }
    return nil unless last_request
    already_verified = events.any? { |e| e.is_a?(LoginCodeVerified) && e.data[:request_event_id] == last_request.event_id }
    already_verified ? nil : last_request
  end
end
