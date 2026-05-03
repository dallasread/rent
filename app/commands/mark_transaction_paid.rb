class MarkTransactionPaid
  class NotFound < CommandError; end
  class AlreadyPaid < CommandError; end
  class InvalidPaidOn < CommandError; end

  def self.call(actor:, tx_id:, paid_on:)
    Authorization.check!(actor: actor, key: self.name)

    tx = Transaction.call(tx_id: tx_id).transaction
    raise NotFound, "Transaction not found." unless tx
    raise AlreadyPaid, "Transaction already paid." if tx.paid?

    d = parse_date(paid_on)
    raise InvalidPaidOn, "Paid-on date is invalid." unless d

    Rails.configuration.event_store.publish(
      TransactionMarkedPaid.new(data: {
        tx_id: tx_id,
        actor_id: actor,
        paid_at: d.to_time
      }),
      stream_name: "Tx$#{tx_id}"
    )
    nil
  end

  def self.parse_date(input)
    Date.parse(input.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
