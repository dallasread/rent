class TransactionRecorded < RailsEventStore::Event
  # data: { tx_id:, lease_id:, kind:, amount_cents:, description:, method:, paid_at:, actor_id:, recorded_at: }
end
