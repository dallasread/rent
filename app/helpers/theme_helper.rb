module ThemeHelper
  # Returns "dark" or "light" based on the perceived luminance of a hex color.
  # Used to set color-scheme so Oat's light-dark() calls resolve correctly.
  def color_scheme_for(hex)
    h = hex.to_s.delete("#")
    return "light" if h.empty?
    h = h.chars.map { |c| c + c }.join if h.length == 3
    return "light" unless h.length == 6
    r = h[0, 2].to_i(16)
    g = h[2, 2].to_i(16)
    b = h[4, 2].to_i(16)
    luma = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
    luma < 0.5 ? "dark" : "light"
  end
end
