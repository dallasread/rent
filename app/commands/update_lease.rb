class UpdateLease
  class NotFound < NotFoundError; end
  class InvalidStartDate < CommandError; end
  class InvalidEndDate < CommandError; end
  class InvalidRent < CommandError; end
  class InvalidFrequency < CommandError; end
  class Overlaps < CommandError; end

  def self.call(lease_id:, actor:, start_date:, rent:, frequency:, end_date: nil)
    Authorization.check!(actor: actor, key: self.name)

    current = Lease.call(lease_id: lease_id).lease
    raise NotFound, "Lease not found." unless current

    start_d = CreateLease.parse_date(start_date)
    raise InvalidStartDate, "Valid start date is required." unless start_d

    end_d = end_date.present? ? CreateLease.parse_date(end_date) : nil
    raise InvalidEndDate, "End date is invalid." if end_date.present? && end_d.nil?
    raise InvalidEndDate, "End date must be after start date." if end_d && end_d <= start_d

    cents = CreateLease.parse_amount_cents(rent)
    raise InvalidRent, "Rent must be a positive number." if cents.nil? || cents <= 0

    raise InvalidFrequency, "Frequency must be one of: #{CreateLease::FREQUENCIES.join(', ')}." unless CreateLease::FREQUENCIES.include?(frequency.to_s)

    raise Overlaps, "Lease overlaps an existing one for this property." if overlap_exists?(current.property_id, current.id, start_d, end_d)

    Rails.configuration.event_store.publish(
      LeaseUpdated.new(data: {
        lease_id: lease_id,
        start_date: start_d.iso8601,
        end_date: end_d&.iso8601,
        rent_cents: cents,
        frequency: frequency.to_s,
        mobile: actor,
        updated_at: Time.current
      }),
      stream_name: "Lease$#{lease_id}"
    )
    nil
  end

  def self.overlap_exists?(property_id, lease_id, start_d, end_d)
    Leases.call.leases
      .select { |l| l.property_id == property_id && l.id != lease_id }
      .any? { |l| CreateLease.ranges_overlap?(start_d, end_d, l.start_date, l.end_date) }
  end
end
