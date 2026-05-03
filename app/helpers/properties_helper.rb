module PropertiesHelper
  # Admin-facing label: address if present, otherwise the public name.
  def property_admin_label(property)
    property.address.presence || property.name
  end

  def property_link(property_id, fallback: "(deleted)")
    return fallback unless property_id

    property = Property.call(property_id: property_id).property
    return fallback unless property

    link_to property_admin_label(property), property_public_path(property.slug)
  end

  def property_name(property_id, fallback: "(deleted)")
    return fallback unless property_id
    property = Property.call(property_id: property_id).property
    property ? property.name : fallback
  end

  # Renders a small property thumbnail (.property-thumb) when the property has
  # at least one photo. The thumbnail is wrapped in a link to the public page.
  # Returns nil when no photo exists, so the call site can simply: `<%= ... %>`.
  def property_thumb(property, size: :thumb, link: true)
    return nil unless property
    photo = property.photos.find { |p| p.blob }
    return nil unless photo
    img = image_tag(photo.variant(size), alt: "#{property.name} thumbnail", class: "property-thumb")
    link ? link_to(img, property_public_path(property.slug)) : img
  end
end
