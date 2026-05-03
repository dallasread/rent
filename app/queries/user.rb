class User
  UserView = Data.define(:id, :mobile, :created_at)
  Result = Data.define(:user)

  def self.call(user_id:)
    return Result.new(user: nil) if user_id.blank?

    event = Rails.configuration.event_store.read
      .stream("User$#{user_id}")
      .of_type([ UserCreated ])
      .first

    return Result.new(user: nil) unless event
    Result.new(user: build(event))
  end

  def self.find_by_mobile(mobile)
    return nil if mobile.blank?
    Users.call.users.find { |u| u.mobile == mobile }
  end

  def self.build(event)
    UserView.new(
      id: event.data[:user_id],
      mobile: event.data[:mobile],
      created_at: event.data[:created_at]
    )
  end
end
