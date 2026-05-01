class TransactionMarkedPaid < RailsEventStore::Event
  # data: { tx_id:, mobile:, paid_at: }
end
