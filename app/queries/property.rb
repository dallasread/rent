class Property
  Photo = Data.define(:id, :blob_id) do
    SIZES = {
      thumb:  { resize_to_limit: [ 200, 200 ] },
      medium: { resize_to_limit: [ 800, 600 ] },
      hero:   { resize_to_limit: [ 1600, 1200 ] }
    }.freeze

    def blob
      ActiveStorage::Blob.find_by(id: blob_id)
    end

    def variant(size)
      raise ArgumentError, "Unknown photo size #{size.inspect}" unless SIZES.key?(size)
      blob&.variant(SIZES[size])
    end
  end

  PropertyView = Data.define(:id, :slug, :name, :address, :beds, :baths, :description, :published, :photos, :added_at, :updated_at, :added_by_id, :last_edited_by_id)
  Result = Data.define(:property)

  EVENT_TYPES = [ PropertyAdded, PropertyUpdated, PropertyRemoved, PropertyPublished, PropertyUnpublished, PhotoAttached, PhotoDetached, PhotosReordered ].freeze

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

      photos_by_id = {}
      order = []
      events.each do |e|
        case e
        when PhotoAttached
          pid = e.data[:photo_id]
          photos_by_id[pid] = Photo.new(id: pid, blob_id: e.data[:blob_id])
          order << pid
        when PhotoDetached
          pid = e.data[:photo_id]
          photos_by_id.delete(pid)
          order.delete(pid)
        when PhotosReordered
          given = Array(e.data[:ordered_photo_ids])
          order = given.select { |pid| photos_by_id.key?(pid) } + order.reject { |pid| given.include?(pid) }
        end
      end
      photos = order.filter_map { |pid| photos_by_id[pid] }

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
        added_by_id: added.data[:actor_id],
        last_edited_by_id: latest_data_event.data[:actor_id]
      )
    end
  end
end
