class IsAdmin
  Result = Data.define(:admin?)

  def self.call(mobile:)
    return Result.new(admin?: false) if mobile.blank?

    found = Rails.configuration.event_store.read
      .of_type([ UserPromotedToAdmin ])
      .each
      .any? { |e| e.data[:mobile] == mobile }

    Result.new(admin?: found)
  end
end
