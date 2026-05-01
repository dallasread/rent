class MarkTransactionPaid
  class NotFound < CommandError; end
  class AlreadyPaid < CommandError; end

  def self.call(actor:, tx_id:)
    Authorization.check!(actor: actor, key: self.name)

    tx = Transaction.call(tx_id: tx_id).transaction
    raise NotFound, "Transaction not found." unless tx
    raise AlreadyPaid, "Transaction already paid." if tx.paid?

    Rails.configuration.event_store.publish(
      TransactionMarkedPaid.new(data: {
        tx_id: tx_id,
        mobile: actor,
        paid_at: Time.current
      }),
      stream_name: "Tx$#{tx_id}"
    )
    nil
  end
end
