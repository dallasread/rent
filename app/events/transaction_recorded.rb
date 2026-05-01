class TransactionRecorded < RailsEventStore::Event
  # data: { tx_id:, lease_id:, amount_cents:, description:, method:, paid_at:, mobile:, recorded_at: }
end
