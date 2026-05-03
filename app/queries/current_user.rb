class CurrentUser
  Result = Data.define(:authenticated?, :id, :mobile, :token)

  UNAUTHENTICATED = Result.new(authenticated?: false, id: nil, mobile: nil, token: nil)

  def self.call(token:)
    return UNAUTHENTICATED if token.blank?

    events = Rails.configuration.event_store.read
      .stream("Token$#{token}")
      .of_type([ LoginCodeVerified, LoggedOut ])
      .to_a

    verified = events.find { |e| e.is_a?(LoginCodeVerified) }
    logged_out = events.any? { |e| e.is_a?(LoggedOut) }
    return UNAUTHENTICATED unless verified && !logged_out

    user_id = verified.data[:user_id]
    user = User.call(user_id: user_id).user
    return UNAUTHENTICATED unless user

    Result.new(authenticated?: true, id: user.id, mobile: user.mobile, token: token)
  end
end
