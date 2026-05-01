class PropertyUpdated < RailsEventStore::Event
  # data: { property_id:, slug:, mobile:, name:, address:, beds:, baths:, description:, updated_at: }
end
