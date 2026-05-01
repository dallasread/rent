class RecordTransaction
  class LeaseNotFound < CommandError; end
  class InvalidAmount < CommandError; end
  class InvalidDescription < CommandError; end
  class InvalidMethod < CommandError; end
  class InvalidKind < CommandError; end
  class InvalidPaidOn < CommandError; end

  METHODS = %w[cash e-transfer cheque credit].freeze
  KINDS = %w[rent deposit fee other].freeze

  def self.call(actor:, lease_id:, amount:, description:, method:, kind:, paid_on:)
    Authorization.check!(actor: actor, key: self.name)

    lease = Lease.call(lease_id: lease_id).lease
    raise LeaseNotFound, "Lease not found." unless lease

    cents = parse_amount_cents(amount)
    raise InvalidAmount, "Amount must be a positive number." if cents.nil? || cents <= 0
    raise InvalidDescription, "Description is required." if description.to_s.strip.empty?
    raise InvalidMethod, "Method must be one of: #{METHODS.join(', ')}." unless METHODS.include?(method.to_s)
    raise InvalidKind, "Kind must be one of: #{KINDS.join(', ')}." unless KINDS.include?(kind.to_s)

    paid_at = if paid_on.present?
      d = parse_date(paid_on)
      raise InvalidPaidOn, "Paid-on date is invalid." unless d
      d.to_time
    end

    event = TransactionRecorded.new(data: {
      tx_id: SecureRandom.uuid,
      lease_id: lease_id,
      kind: kind.to_s,
      amount_cents: cents,
      description: description.to_s.strip,
      method: method.to_s,
      paid_at: paid_at,
      mobile: actor,
      recorded_at: Time.current
    })
    Rails.configuration.event_store.publish(event, stream_name: "Lease$#{lease_id}")
    Rails.configuration.event_store.link([ event.event_id ], stream_name: "Transactions")
    nil
  end

  def self.parse_amount_cents(input)
    return nil if input.to_s.strip.empty?
    f = Float(input.to_s)
    (f * 100).round
  rescue ArgumentError, TypeError
    nil
  end

  def self.parse_date(input)
    Date.parse(input.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
