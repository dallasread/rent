class Property
  Photo = Data.define(:id, :blob_id) do
    def blob
      ActiveStorage::Blob.find_by(id: blob_id)
    end
  end

  PropertyView = Data.define(:id, :slug, :name, :address, :beds, :baths, :description, :published, :photos, :added_at, :updated_at, :added_by, :last_edited_by)
  Result = Data.define(:property)

  EVENT_TYPES = [ PropertyAdded, PropertyUpdated, PropertyRemoved, PropertyPublished, PropertyUnpublished, PhotoAttached ].freeze

  def self.call(property_id:)
    events = Rails.configuration.event_store.read
      .stream("Property$#{property_id}")
      .of_type(EVENT_TYPES)
      .to_a

    fold = PropertyFold.call(events)
    raise NotFoundError, "Property not found." unless fold
    Result.new(property: fold)
  end

  module PropertyFold
    def self.call(events)
      return nil if events.empty?
      return nil if events.last.is_a?(PropertyRemoved)
      added = events.find { |e| e.is_a?(PropertyAdded) }
      return nil unless added

      latest_data_event = events.reverse.find { |e| e.is_a?(PropertyAdded) || e.is_a?(PropertyUpdated) }
      latest_slug_event = events.reverse.find { |e| (e.is_a?(PropertyAdded) || e.is_a?(PropertyUpdated)) && e.data[:slug].present? }
      slug = latest_slug_event&.data&.dig(:slug) || Slug.normalize(latest_data_event.data[:name]) || "property-#{added.data[:property_id][0, 8]}"

      latest_publish_event = events.reverse.find { |e| e.is_a?(PropertyPublished) || e.is_a?(PropertyUnpublished) }
      published = latest_publish_event.is_a?(PropertyPublished)

      photos = events.select { |e| e.is_a?(PhotoAttached) }.map { |e| Photo.new(id: e.data[:photo_id], blob_id: e.data[:blob_id]) }

      PropertyView.new(
        id: latest_data_event.data[:property_id],
        slug: slug,
        name: latest_data_event.data[:name],
        address: latest_data_event.data[:address].to_s,
        beds: latest_data_event.data[:beds],
        baths: latest_data_event.data[:baths],
        description: latest_data_event.data[:description],
        published: published,
        photos: photos,
        added_at: added.data[:added_at],
        updated_at: latest_data_event.is_a?(PropertyUpdated) ? latest_data_event.data[:updated_at] : nil,
        added_by: added.data[:mobile],
        last_edited_by: latest_data_event.data[:mobile]
      )
    end
  end
end
