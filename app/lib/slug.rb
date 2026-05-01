module Slug
  def self.normalize(input)
    input.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-+|-+$/, "").presence
  end

  def self.unique_for(base, taken)
    return base unless taken.include?(base)
    n = 2
    n += 1 while taken.include?("#{base}-#{n}")
    "#{base}-#{n}"
  end
end
