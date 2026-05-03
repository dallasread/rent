class TransactionUnarchived < RailsEventStore::Event
  # data: { tx_id:, actor_id:, unarchived_at: }
end
