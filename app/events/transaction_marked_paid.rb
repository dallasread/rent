class TransactionMarkedPaid < RailsEventStore::Event
  # data: { tx_id:, actor_id:, paid_at: }
end
