class RecordTransaction
  class LeaseNotFound < CommandError; end
  class InvalidAmount < CommandError; end
  class InvalidDescription < CommandError; end

  def self.call(actor:, lease_id:, amount:, paid_by:, description:, method:, note:, paid:)
    Authorization.check!(actor: actor, key: self.name)

    lease = Lease.call(lease_id: lease_id).lease
    raise LeaseNotFound, "Lease not found." unless lease

    cents = parse_amount_cents(amount)
    raise InvalidAmount, "Amount must be a positive number." if cents.nil? || cents <= 0
    raise InvalidDescription, "Description is required." if description.to_s.strip.empty?

    Rails.configuration.event_store.publish(
      TransactionRecorded.new(data: {
        tx_id: SecureRandom.uuid,
        lease_id: lease_id,
        amount_cents: cents,
        paid_by: paid_by.to_s.strip,
        description: description.to_s.strip,
        method: method.to_s.strip,
        note: note.to_s,
        paid_at: paid ? Time.current : nil,
        mobile: actor,
        recorded_at: Time.current
      }),
      stream_name: "Lease$#{lease_id}"
    ).tap do
      # link to global Transactions stream as well
    end

    last = Rails.configuration.event_store.read.stream("Lease$#{lease_id}").of_type([ TransactionRecorded ]).backward.limit(1).to_a.first
    Rails.configuration.event_store.link([ last.event_id ], stream_name: "Transactions") if last
    nil
  end

  def self.parse_amount_cents(input)
    return nil if input.to_s.strip.empty?
    f = Float(input.to_s)
    (f * 100).round
  rescue ArgumentError, TypeError
    nil
  end
end
