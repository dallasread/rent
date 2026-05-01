class PropertyUpdated < RailsEventStore::Event
  # data: { property_id:, slug:, mobile:, name:, beds:, baths:, description:, updated_at: }
end
