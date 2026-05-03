class CurrentUserByApiToken
  def self.call(token:)
    return CurrentUser::UNAUTHENTICATED if token.blank?

    match = ApiTokens.call.api_tokens.find { |t| t.token == token && !t.revoked? }
    return CurrentUser::UNAUTHENTICATED unless match

    user = User.call(user_id: match.created_by_id).user
    return CurrentUser::UNAUTHENTICATED unless user

    CurrentUser::Result.new(authenticated?: true, id: user.id, mobile: user.mobile, token: token)
  end
end
