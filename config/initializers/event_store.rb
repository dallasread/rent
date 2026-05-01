Rails.configuration.event_store = RailsEventStore::Client.new

Rails.configuration.to_prepare do
  Rails.configuration.event_store.subscribe(
    ->(event) { SendLoginCodeSms.call(event) },
    to: [ LoginCodeRequested ]
  )
end
