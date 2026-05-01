class RequestLoginCode
  CODE_TTL = 10.minutes
  RATE_LIMIT = 5
  RATE_WINDOW = 1.hour

  class InvalidMobile < CommandError; end
  class RateLimited < CommandError; end

  def self.call(mobile:, ip:)
    normalized = Mobile.normalize(mobile)
    raise InvalidMobile, "Invalid mobile number." unless normalized
    raise RateLimited, "Too many attempts. Try again later." if rate_limited?(normalized)

    Rails.configuration.event_store.publish(
      LoginCodeRequested.new(data: {
        mobile: normalized,
        code: format("%06d", SecureRandom.random_number(1_000_000)),
        expires_at: Time.current + CODE_TTL,
        ip: ip,
        requested_at: Time.current
      }),
      stream_name: "Mobile$#{normalized}"
    )
    nil
  end

  def self.rate_limited?(mobile)
    cutoff = Time.current - RATE_WINDOW
    recent = Rails.configuration.event_store.read
      .stream("Mobile$#{mobile}")
      .of_type([ LoginCodeRequested ])
      .backward
      .limit(RATE_LIMIT)
      .to_a
    recent.count { |e| e.metadata[:timestamp] >= cutoff } >= RATE_LIMIT
  end
end
