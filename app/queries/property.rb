class Property
  PropertyView = Data.define(:id, :slug, :name, :beds, :baths, :description, :added_at, :updated_at, :added_by, :last_edited_by)
  Result = Data.define(:property)

  def self.call(property_id:)
    events = Rails.configuration.event_store.read
      .stream("Property$#{property_id}")
      .of_type([ PropertyAdded, PropertyUpdated, PropertyRemoved ])
      .to_a

    Result.new(property: PropertyFold.call(events))
  end

  module PropertyFold
    def self.call(events)
      return nil if events.empty?
      return nil if events.last.is_a?(PropertyRemoved)
      added = events.find { |e| e.is_a?(PropertyAdded) }
      return nil unless added
      latest = events.reverse.find { |e| e.is_a?(PropertyAdded) || e.is_a?(PropertyUpdated) }

      slug = added.data[:slug] || Slug.normalize(added.data[:name]) || "property-#{added.data[:property_id][0, 8]}"

      PropertyView.new(
        id: latest.data[:property_id],
        slug: slug,
        name: latest.data[:name],
        beds: latest.data[:beds],
        baths: latest.data[:baths],
        description: latest.data[:description],
        added_at: added.data[:added_at],
        updated_at: latest.is_a?(PropertyUpdated) ? latest.data[:updated_at] : nil,
        added_by: added.data[:mobile],
        last_edited_by: latest.data[:mobile]
      )
    end
  end
end
