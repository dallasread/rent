class TransactionUpdated < RailsEventStore::Event
  # data: { tx_id:, amount_cents:, description:, method:, kind:, paid_at:, mobile:, updated_at: }
end
