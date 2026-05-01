class TransactionRecorded < RailsEventStore::Event
  # data: { tx_id:, lease_id:, amount_cents:, paid_by:, description:, method:, note:, paid_at:, mobile:, recorded_at: }
end
