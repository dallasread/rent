module SmsClient
  def self.deliver(to:, body:)
    backend.deliver(to: to, body: body)
  end

  def self.backend
    @backend ||= default_backend
  end

  def self.backend=(backend)
    @backend = backend
  end

  def self.default_backend
    Rails.env.test? ? TestBackend : TwilioBackend
  end

  module TwilioBackend
    def self.deliver(to:, body:)
      creds = Rails.application.credentials.twilio
      client = Twilio::REST::Client.new(creds[:account_sid], creds[:auth_token])
      client.messages.create(from: creds[:number], to: to, body: body)
    end
  end

  module TestBackend
    def self.messages
      @messages ||= []
    end

    def self.deliver(to:, body:)
      messages << { to: to, body: body, sent_at: Time.current }
    end

    def self.reset!
      @messages = []
    end
  end
end
