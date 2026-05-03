class UnarchiveTransaction
  def self.call(tx_id:, actor:)
    Authorization.check!(actor: actor, key: name)
    Transaction.call(tx_id: tx_id)

    Rails.configuration.event_store.publish(
      TransactionUnarchived.new(data: {
        tx_id: tx_id,
        actor_id: actor,
        unarchived_at: Time.current
      }),
      stream_name: "Tx$#{tx_id}"
    )
    nil
  end
end
