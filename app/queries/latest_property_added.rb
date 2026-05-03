class LatestPropertyAdded
  Result = Data.define(:property_id, :slug)

  def self.call(user_id:)
    event = Rails.configuration.event_store.read
      .stream("Properties")
      .of_type([ PropertyAdded ])
      .backward
      .each
      .find { |e| e.data[:actor_id] == user_id }

    Result.new(
      property_id: event&.data&.dig(:property_id),
      slug: event&.data&.dig(:slug)
    )
  end
end
