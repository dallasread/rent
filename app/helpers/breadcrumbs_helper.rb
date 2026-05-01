module BreadcrumbsHelper
  # Render Oat-style breadcrumbs.
  #
  #   breadcrumbs(
  #     ["Properties", properties_path],
  #     [property.name, property_path(property.slug)],
  #     [@application.name]                              # current page (no path)
  #   )
  def breadcrumbs(*crumbs)
    render "shared/breadcrumbs", crumbs: crumbs
  end
end
