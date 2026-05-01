class PropertyBySlug
  Result = Data.define(:property)

  def self.call(slug:)
    match = Properties.call.properties.find { |p| p.slug == slug }
    Result.new(property: match)
  end
end
