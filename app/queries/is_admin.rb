class IsAdmin
  Result = Data.define(:admin?)

  def self.call(user_id:)
    return Result.new(admin?: false) if user_id.blank?

    found = Rails.configuration.event_store.read
      .of_type([ UserPromotedToAdmin ])
      .each
      .any? { |e| e.data[:user_id] == user_id }

    Result.new(admin?: found)
  end
end
