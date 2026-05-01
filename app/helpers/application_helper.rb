module ApplicationHelper
  # Renders a date or time as a compact string in the configured time zone,
  # with a tooltip (title attribute) showing the full date, time, and zone.
  # Returns nil if value is nil so callers can chain `&.`.
  def datetime_with_tooltip(value, format: :short)
    return nil if value.nil?
    t = value.is_a?(Date) && !value.is_a?(DateTime) ? value : value.to_time.in_time_zone
    short = t.is_a?(Date) ? t.iso8601 : t.to_fs(format)
    full  = t.is_a?(Date) ? t.strftime("%A, %B %-d, %Y") : t.strftime("%A, %B %-d, %Y at %-l:%M %p %Z")
    content_tag(:time, short, datetime: t.iso8601, title: full)
  end
end
