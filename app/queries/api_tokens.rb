class ApiTokens
  ApiTokenView = Data.define(:id, :name, :token, :created_by, :created_at, :revoked_at) do
    def revoked?
      !revoked_at.nil?
    end

    def masked
      "#{token[0, 6]}…#{token[-4, 4]}"
    end
  end

  Result = Data.define(:api_tokens)

  def self.call
    events = Rails.configuration.event_store.read
      .stream("ApiTokens")
      .of_type([ ApiTokenCreated ])
      .to_a

    revoked_at = revoked_lookup

    tokens = events.map do |e|
      ApiTokenView.new(
        id: e.data[:token_id],
        name: e.data[:name].to_s,
        token: e.data[:token].to_s,
        created_by: e.data[:mobile].to_s,
        created_at: e.data[:created_at],
        revoked_at: revoked_at[e.data[:token_id]]
      )
    end

    Result.new(api_tokens: tokens.sort_by { |t| t.created_at || Time.current }.reverse)
  end

  def self.revoked_lookup
    Rails.configuration.event_store.read
      .of_type([ ApiTokenRevoked ])
      .to_a
      .each_with_object({}) { |e, h| h[e.data[:token_id]] = e.data[:revoked_at] }
  end
end
