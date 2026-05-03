class PropertyRemoved < RailsEventStore::Event
  # data: { property_id:, actor_id:, removed_at: }
end
