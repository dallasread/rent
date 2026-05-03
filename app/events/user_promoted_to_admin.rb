class UserPromotedToAdmin < RailsEventStore::Event
  # data: { user_id:, actor_id:, promoted_at: }
end
