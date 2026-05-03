class PropertyAdded < RailsEventStore::Event
  # data: { property_id:, slug:, actor_id:, name:, address:, beds:, baths:, description:, added_at: }
end
