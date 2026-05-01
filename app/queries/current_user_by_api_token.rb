class CurrentUserByApiToken
  def self.call(token:)
    blank = CurrentUser::Result.new(authenticated?: false, mobile: nil, token: nil)
    return blank if token.blank?

    match = ApiTokens.call.api_tokens.find { |t| t.token == token && !t.revoked? }
    return blank unless match

    CurrentUser::Result.new(authenticated?: true, mobile: match.created_by, token: token)
  end
end
