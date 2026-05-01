class CurrentUser
  Result = Data.define(:authenticated?, :mobile, :token)

  def self.call(token:)
    return Result.new(authenticated?: false, mobile: nil, token: nil) if token.blank?

    events = Rails.configuration.event_store.read
      .stream("Token$#{token}")
      .of_type([ LoginCodeVerified, LoggedOut ])
      .to_a

    verified = events.find { |e| e.is_a?(LoginCodeVerified) }
    logged_out = events.any? { |e| e.is_a?(LoggedOut) }

    if verified && !logged_out
      Result.new(authenticated?: true, mobile: verified.data[:mobile], token: token)
    else
      Result.new(authenticated?: false, mobile: nil, token: nil)
    end
  end
end
