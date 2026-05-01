class LatestAuthToken
  Result = Data.define(:token)

  def self.call(mobile:)
    event = Rails.configuration.event_store.read
      .stream("Mobile$#{mobile}")
      .of_type([LoginCodeVerified])
      .last
    Result.new(token: event&.data&.dig(:token))
  end
end
