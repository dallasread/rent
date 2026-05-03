class AdminMobiles
  Result = Data.define(:mobiles)

  def self.call
    user_ids = Rails.configuration.event_store.read
      .of_type([ UserPromotedToAdmin ])
      .to_a
      .map { |e| e.data[:user_id] }
      .uniq

    by_id = Users.call.users.index_by(&:id)
    Result.new(mobiles: user_ids.filter_map { |id| by_id[id]&.mobile })
  end
end
