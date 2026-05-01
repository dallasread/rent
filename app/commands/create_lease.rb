class CreateLease
  class ApplicantNotFound < NotFoundError; end
  class PropertyNotFound < NotFoundError; end
  class InvalidStartDate < CommandError; end
  class InvalidEndDate < CommandError; end
  class InvalidRent < CommandError; end
  class InvalidFrequency < CommandError; end
  class Overlaps < CommandError; end

  FAR_FUTURE = Date.new(9999, 12, 31).freeze
  FREQUENCIES = %w[monthly weekly biweekly quarterly].freeze

  def self.call(actor:, applicant_id:, property_id:, start_date:, rent:, frequency: "monthly", end_date: nil, tax_ids: [])
    Authorization.check!(actor: actor, key: self.name)

    applicant = Applications.call.applications.find { |a| a.id == applicant_id }
    raise ApplicantNotFound, "Applicant not found." unless applicant

    property = Property.call(property_id: property_id).property
    raise PropertyNotFound, "Property not found." unless property

    start_d = parse_date(start_date)
    raise InvalidStartDate, "Valid start date is required." unless start_d

    end_d = end_date.present? ? parse_date(end_date) : nil
    raise InvalidEndDate, "End date is invalid." if end_date.present? && end_d.nil?
    raise InvalidEndDate, "End date must be after start date." if end_d && end_d <= start_d

    cents = parse_amount_cents(rent)
    raise InvalidRent, "Rent must be a positive number." if cents.nil? || cents <= 0

    raise InvalidFrequency, "Frequency must be one of: #{FREQUENCIES.join(', ')}." unless FREQUENCIES.include?(frequency.to_s)

    raise Overlaps, "Lease overlaps an existing one for this property." if overlap_exists?(property_id, start_d, end_d)

    event = LeaseCreated.new(data: {
      lease_id: SecureRandom.uuid,
      property_id: property_id,
      applicant_id: applicant_id,
      start_date: start_d.iso8601,
      end_date: end_d&.iso8601,
      rent_cents: cents,
      frequency: frequency.to_s,
      tax_ids: Array(tax_ids).reject(&:blank?),
      mobile: actor,
      created_at: Time.current
    })
    Rails.configuration.event_store.publish(event, stream_name: "Property$#{property_id}")
    Rails.configuration.event_store.link([ event.event_id ], stream_name: "Leases")
    nil
  end

  def self.parse_date(input)
    Date.parse(input.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def self.parse_amount_cents(input)
    return nil if input.to_s.strip.empty?
    f = Float(input.to_s)
    (f * 100).round
  rescue ArgumentError, TypeError
    nil
  end

  def self.overlap_exists?(property_id, start_d, end_d)
    Leases.call.leases
      .select { |l| l.property_id == property_id }
      .any? { |l| ranges_overlap?(start_d, end_d, l.start_date, l.end_date) }
  end

  def self.ranges_overlap?(a_start, a_end, b_start, b_end)
    a_end_eff = a_end || FAR_FUTURE
    b_end_eff = b_end || FAR_FUTURE
    a_start <= b_end_eff && a_end_eff >= b_start
  end
end
