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
      account_sid, auth_token, number = credentials
      raise "Twilio not configured: set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_NUMBER" if [ account_sid, auth_token, number ].any?(&:blank?)

      client = Twilio::REST::Client.new(account_sid, auth_token)
      client.messages.create(from: number, to: to, body: body)
    end

    def self.credentials
      env = [ ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"], ENV["TWILIO_NUMBER"] ]
      return env if env.all?(&:present?)

      twilio = Rails.application.credentials.twilio || {}
      [ twilio[:account_sid], twilio[:auth_token], twilio[:number] ]
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
