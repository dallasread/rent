class PropertyUpdated < RailsEventStore::Event
  # data: { property_id:, slug:, actor_id:, name:, address:, beds:, baths:, description:, updated_at: }
end
