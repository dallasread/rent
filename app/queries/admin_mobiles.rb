class AdminMobiles
  Result = Data.define(:mobiles)

  def self.call
    events = Rails.configuration.event_store.read
      .of_type([ UserPromotedToAdmin ])
      .to_a
    Result.new(mobiles: events.map { |e| e.data[:mobile].to_s }.uniq)
  end
end
