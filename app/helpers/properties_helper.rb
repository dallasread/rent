module PropertiesHelper
  # Admin-facing label: address if present, otherwise the public name.
  def property_admin_label(property)
    property.address.presence || property.name
  end

  def property_link(property_id, fallback: "(deleted)")
    return fallback unless property_id

    property = Property.call(property_id: property_id).property
    return fallback unless property

    link_to property_admin_label(property), property_path(property.slug)
  end

  def property_name(property_id, fallback: "(deleted)")
    return fallback unless property_id
    property = Property.call(property_id: property_id).property
    property ? property.name : fallback
  end
end
