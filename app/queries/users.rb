class Users
  Result = Data.define(:users)

  def self.call
    events = Rails.configuration.event_store.read
      .of_type([ UserCreated ])
      .to_a
    Result.new(users: events.map { |e| User.build(e) })
  end
end
