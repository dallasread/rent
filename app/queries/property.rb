class Property
  PropertyView = Data.define(:id, :slug, :name, :beds, :baths, :description, :published, :added_at, :updated_at, :added_by, :last_edited_by)
  Result = Data.define(:property)

  EVENT_TYPES = [ PropertyAdded, PropertyUpdated, PropertyRemoved, PropertyPublished, PropertyUnpublished ].freeze

  def self.call(property_id:)
    events = Rails.configuration.event_store.read
      .stream("Property$#{property_id}")
      .of_type(EVENT_TYPES)
      .to_a

    Result.new(property: PropertyFold.call(events))
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

      PropertyView.new(
        id: latest_data_event.data[:property_id],
        slug: slug,
        name: latest_data_event.data[:name],
        beds: latest_data_event.data[:beds],
        baths: latest_data_event.data[:baths],
        description: latest_data_event.data[:description],
        published: published,
        added_at: added.data[:added_at],
        updated_at: latest_data_event.is_a?(PropertyUpdated) ? latest_data_event.data[:updated_at] : nil,
        added_by: added.data[:mobile],
        last_edited_by: latest_data_event.data[:mobile]
      )
    end
  end
end
