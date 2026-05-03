class TransactionArchived < RailsEventStore::Event
  # data: { tx_id:, actor_id:, archived_at: }
end
