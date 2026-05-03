class PhotoAttached < RailsEventStore::Event
  # data: { property_id:, photo_id:, blob_id:, actor_id:, attached_at: }
end
