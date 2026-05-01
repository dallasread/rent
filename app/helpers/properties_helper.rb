module PropertiesHelper
  def property_link(property_id, fallback: "(deleted)")
    return fallback unless property_id

    property = Property.call(property_id: property_id).property
    return fallback unless property

    link_to property.name, property_path(property.slug)
  end

  def property_name(property_id, fallback: "(deleted)")
    return fallback unless property_id
    property = Property.call(property_id: property_id).property
    property ? property.name : fallback
  end
end
