class NotifyAdminOfApplication
  def self.call(event)
    mobiles = AdminMobiles.call.mobiles
    return if mobiles.empty?

    property_label = if event.data[:property_id]
      Properties.call.properties.find { |p| p.id == event.data[:property_id] }&.name || "(unknown property)"
    else
      "(no specific property)"
    end

    body = "New application from #{event.data[:name]} (#{event.data[:mobile]}) for #{property_label}."
    mobiles.each { |m| SmsClient.deliver(to: m, body: body) }
  end
end
