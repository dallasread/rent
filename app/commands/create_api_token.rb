class CreateApiToken
  class InvalidName < CommandError; end

  def self.call(actor:, name:)
    Authorization.check!(actor: actor, key: self.name)
    raise InvalidName, "Name is required." if name.to_s.strip.empty?

    token_id = SecureRandom.uuid
    token = SecureRandom.hex(32)
    Rails.configuration.event_store.publish(
      ApiTokenCreated.new(data: {
        token_id: token_id,
        name: name.to_s.strip,
        token: token,
        mobile: actor,
        created_at: Time.current
      }),
      stream_name: "ApiToken$#{token_id}"
    ).then do
      Rails.configuration.event_store.link(
        [ Rails.configuration.event_store.read.stream("ApiToken$#{token_id}").last.event_id ],
        stream_name: "ApiTokens"
      )
    end
    nil
  end
end
