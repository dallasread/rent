class LatestPropertyAdded
  Result = Data.define(:property_id)

  def self.call(mobile:)
    event = Rails.configuration.event_store.read
      .stream("Properties")
      .of_type([ PropertyAdded ])
      .backward
      .each
      .find { |e| e.data[:mobile] == mobile }

    Result.new(property_id: event&.data&.dig(:property_id))
  end
end
