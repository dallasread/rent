class UpdateTransaction
  class NotFound < NotFoundError; end
  class InvalidAmount < CommandError; end
  class InvalidDescription < CommandError; end
  class InvalidMethod < CommandError; end
  class InvalidKind < CommandError; end
  class InvalidPaidOn < CommandError; end

  def self.call(actor:, tx_id:, amount:, description:, method:, kind:, paid_on:)
    Authorization.check!(actor: actor, key: self.name)

    current = Transaction.call(tx_id: tx_id).transaction
    raise NotFound, "Transaction not found." unless current

    cents = RecordTransaction.parse_amount_cents(amount)
    raise InvalidAmount, "Amount must be a positive number." if cents.nil? || cents <= 0
    raise InvalidDescription, "Description is required." if description.to_s.strip.empty?
    raise InvalidMethod, "Method must be one of: #{RecordTransaction::METHODS.join(', ')}." unless RecordTransaction::METHODS.include?(method.to_s)
    raise InvalidKind, "Kind is required." if kind.to_s.strip.empty?

    paid_at = if paid_on.present?
      d = RecordTransaction.parse_date(paid_on)
      raise InvalidPaidOn, "Paid-on date is invalid." unless d
      d.to_time
    end

    Rails.configuration.event_store.publish(
      TransactionUpdated.new(data: {
        tx_id: tx_id,
        amount_cents: cents,
        description: description.to_s.strip,
        method: method.to_s,
        kind: kind.to_s.strip,
        paid_at: paid_at,
        actor_id: actor,
        updated_at: Time.current
      }),
      stream_name: "Tx$#{tx_id}"
    )
    nil
  end
end
