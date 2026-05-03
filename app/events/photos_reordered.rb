class PhotosReordered < RailsEventStore::Event
  # data: { property_id:, ordered_photo_ids:, actor_id:, reordered_at: }
end
