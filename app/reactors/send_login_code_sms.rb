class SendLoginCodeSms
  def self.call(event)
    SmsClient.deliver(
      to: event.data[:mobile],
      body: "Your Rent code: #{event.data[:code]}"
    )
  end
end
