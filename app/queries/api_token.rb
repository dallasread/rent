class ApiToken
  Result = Data.define(:api_token)

  def self.call(token_id:)
    tk = ApiTokens.call.api_tokens.find { |t| t.id == token_id }
    Result.new(api_token: tk)
  end
end
