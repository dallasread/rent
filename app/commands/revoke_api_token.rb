class RevokeApiToken
  class NotFound < CommandError; end
  class AlreadyRevoked < CommandError; end

  def self.call(actor:, token_id:)
    Authorization.check!(actor: actor, key: self.name)

    tk = ApiToken.call(token_id: token_id).api_token
    raise NotFound, "API token not found." unless tk
    raise AlreadyRevoked, "API token already revoked." if tk.revoked?

    Rails.configuration.event_store.publish(
      ApiTokenRevoked.new(data: {
        token_id: token_id,
        actor_id: actor,
        revoked_at: Time.current
      }),
      stream_name: "ApiToken$#{token_id}"
    )
    nil
  end
end
